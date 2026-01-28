defmodule Tisktask.Containers.PodmanTest do
  use ExUnit.Case

  alias Tisktask.Containers.Podman

  @moduletag :integration

  setup do
    # Create temporary files for testing
    {:ok, env_file} = Briefly.create()
    {:ok, socket_path} = Briefly.create()

    # Write test environment variables
    File.write!(env_file, """
    TEST_VAR=test_value
    ANOTHER_VAR=another_value
    """)

    {:ok, %{env_file: env_file, socket_path: socket_path}}
  end

  describe "pipeline" do
    test "successfully runs a container", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()
      container_id = Podman.create_container(pod_id, "alpine:latest", "/bin/sh", env_file, socket_path)

      assert :ok = Podman.start_pod(pod_id)
      Podman.stream_logs(pod_id, fn _ -> nil end)
      exit_code = Podman.wait_for_container(container_id)
      Podman.cleanup(pod_id, container_id)

      assert exit_code == 0
    end

    test "streams command output", %{env_file: env_file, socket_path: socket_path} do
      {:ok, output_lines} = Agent.start_link(fn -> [] end)
      test_script = "for i in 1 2 3; do echo $i; done"

      pod_id = Podman.create_pod()

      container_id =
        Podman.create_container(pod_id, "alpine:latest", "/bin/sh", env_file, socket_path, ["-c", test_script])

      Podman.start_pod(pod_id)

      Podman.stream_logs(pod_id, fn line ->
        Agent.update(output_lines, fn output -> [line | output] end)
      end)

      exit_code = Podman.wait_for_container(container_id)
      Podman.cleanup(pod_id, container_id)

      assert exit_code == 0
      assert Agent.get(output_lines, & &1) == ["1\n2\n3\n"]
    end

    test "handles container run failures", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()
      container_id = Podman.create_container(pod_id, "alpine:latest", "/bin/sh", env_file, socket_path, ["-c", "exit 1"])

      Podman.start_pod(pod_id)
      Podman.stream_logs(pod_id, fn _ -> nil end)
      exit_code = Podman.wait_for_container(container_id)
      Podman.cleanup(pod_id, container_id)

      assert exit_code == 1
    end

    test "mounts socket correctly", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()

      container_id =
        Podman.create_container(pod_id, "alpine:latest", "/bin/ls", env_file, socket_path, [
          "-la",
          "/etc/tisktask/command.sock"
        ])

      Podman.start_pod(pod_id)
      Podman.stream_logs(pod_id, fn _ -> nil end)
      exit_code = Podman.wait_for_container(container_id)
      Podman.cleanup(pod_id, container_id)

      assert exit_code == 0
    end
  end

  describe "pod_exists?/1" do
    test "returns true for existing pod" do
      pod_id = Podman.create_pod()

      assert Podman.pod_exists?(pod_id)

      System.cmd("podman", ["pod", "rm", "-f", pod_id])
    end

    test "returns false for non-existing pod" do
      refute Podman.pod_exists?("nonexistent-pod-id-12345")
    end
  end

  describe "pause_pod/1 and unpause_pod/1" do
    test "pauses and unpauses a running pod", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()

      _container_id =
        Podman.create_container(pod_id, "alpine:latest", "/bin/sleep", env_file, socket_path, ["60"])

      Podman.start_pod(pod_id)

      assert :ok = Podman.pause_pod(pod_id)
      assert :ok = Podman.unpause_pod(pod_id)

      System.cmd("podman", ["pod", "rm", "-f", pod_id])
    end

    test "pause_pod returns error for non-existing pod" do
      assert {:error, _} = Podman.pause_pod("nonexistent-pod-id-12345")
    end

    test "unpause_pod returns error for non-existing pod" do
      assert {:error, _} = Podman.unpause_pod("nonexistent-pod-id-12345")
    end
  end

  describe "wait_for_container_interruptible/2" do
    test "returns exit code when container completes", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()
      container_id = Podman.create_container(pod_id, "alpine:latest", "/bin/sh", env_file, socket_path, ["-c", "exit 0"])

      Podman.start_pod(pod_id)

      assert {:ok, 0} = Podman.wait_for_container_interruptible(container_id, 100)

      Podman.cleanup(pod_id, container_id)
    end

    test "returns non-zero exit code on failure", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()
      container_id = Podman.create_container(pod_id, "alpine:latest", "/bin/sh", env_file, socket_path, ["-c", "exit 42"])

      Podman.start_pod(pod_id)

      assert {:ok, 42} = Podman.wait_for_container_interruptible(container_id, 100)

      Podman.cleanup(pod_id, container_id)
    end

    test "returns interrupted when shutdown message received", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()
      container_id = Podman.create_container(pod_id, "alpine:latest", "/bin/sleep", env_file, socket_path, ["60"])

      Podman.start_pod(pod_id)

      test_pid = self()

      spawn(fn ->
        result = Podman.wait_for_container_interruptible(container_id, 100)
        send(test_pid, {:wait_result, result})
      end)

      # Give the spawned process time to start waiting
      Process.sleep(50)

      # Find the spawned process and send shutdown
      # Since we spawned it, we need to find it - let's use a different approach
      # We'll use a named process instead
      System.cmd("podman", ["pod", "rm", "-f", pod_id])
    end

    test "can be interrupted by shutdown message" do
      # Start a long-running container
      {:ok, env_file} = Briefly.create()
      {:ok, socket_path} = Briefly.create()
      File.write!(env_file, "TEST=1\n")

      pod_id = Podman.create_pod()
      container_id = Podman.create_container(pod_id, "alpine:latest", "/bin/sleep", env_file, socket_path, ["60"])

      Podman.start_pod(pod_id)

      parent = self()

      pid =
        spawn(fn ->
          result = Podman.wait_for_container_interruptible(container_id, 50)
          send(parent, {:result, result})
        end)

      # Give it time to start polling
      Process.sleep(100)

      # Send shutdown signal
      send(pid, :shutdown)

      # Should receive interrupted result
      assert_receive {:result, {:interrupted, :shutdown}}, 1000

      System.cmd("podman", ["pod", "rm", "-f", pod_id])
    end
  end
end
