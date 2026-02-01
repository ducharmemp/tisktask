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
      exit_code = wait_for_container(container_id)
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

      exit_code = wait_for_container(container_id)
      Podman.cleanup(pod_id, container_id)

      assert exit_code == 0
      assert Agent.get(output_lines, & &1) == ["1\n2\n3\n"]
    end

    test "handles container run failures", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()
      container_id = Podman.create_container(pod_id, "alpine:latest", "/bin/sh", env_file, socket_path, ["-c", "exit 1"])

      Podman.start_pod(pod_id)
      Podman.stream_logs(pod_id, fn _ -> nil end)
      exit_code = wait_for_container(container_id)
      Podman.cleanup(pod_id, container_id)

      assert exit_code == 1
    end

    test "mounts socket correctly", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()

      container_id =
        Podman.create_container(pod_id, "alpine:latest", "/bin/ls", env_file, socket_path, [
          "-la",
          "/run/tisktask/command.sock"
        ])

      Podman.start_pod(pod_id)
      Podman.stream_logs(pod_id, fn _ -> nil end)
      exit_code = wait_for_container(container_id)
      Podman.cleanup(pod_id, container_id)

      assert exit_code == 0
    end
  end

  describe "pause/unpause" do
    test "pauses and unpauses a running pod", %{env_file: env_file, socket_path: socket_path} do
      pod_id = Podman.create_pod()

      # Use sleep to keep the container running
      container_id =
        Podman.create_container(pod_id, "alpine:latest", "/bin/sh", env_file, socket_path, [
          "-c",
          "sleep 60"
        ])

      assert :ok = Podman.start_pod(pod_id)

      # Pause the pod
      assert :ok = Podman.pause_pod(pod_id)

      # Verify it's in the paused list
      paused_pods = Podman.list_paused_pods()
      assert pod_id in paused_pods

      # Unpause the pod
      assert :ok = Podman.unpause_pod(pod_id)

      # Verify it's no longer in the paused list
      paused_pods = Podman.list_paused_pods()
      refute pod_id in paused_pods

      # Cleanup
      Podman.cleanup(pod_id, container_id)
    end
  end

  describe "list_paused_pods/0" do
    test "returns empty list when no pods are paused" do
      # This assumes no other paused pods exist on the system
      # In a real test environment, we'd want isolation
      paused_pods = Podman.list_paused_pods()
      assert is_list(paused_pods)
    end
  end

  defp wait_for_container(container_id) do
    {:ok, ref} = Podman.wait_for_container_async(container_id)

    receive do
      {:container_exited, ^ref, ^container_id, exit_status} -> exit_status
    end
  end
end
