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

  describe "run_job/5" do
    test "successfully runs a container", %{env_file: env_file, socket_path: socket_path} do
      result =
        Podman.run_job(
          "alpine:latest",
          "/bin/sh",
          env_file,
          socket_path
        )

      assert match?({:status, 0}, result)
    end

    test "streams command output", %{env_file: env_file, socket_path: socket_path} do
      {:ok, output_lines} = Agent.start_link(fn -> [] end)
      test_script = "for i in 1 2 3; do echo $i; done"

      result =
        Podman.run_job(
          "alpine:latest",
          "/bin/sh",
          env_file,
          socket_path,
          into: fn line ->
            Agent.update(output_lines, fn output -> [line | output] end)
          end,
          args: ["-c", "#{test_script}"]
        )

      assert match?({:status, 0}, result)
      assert Agent.get(output_lines, & &1) == ["1\n2\n3\n"]
    end

    test "handles container run failures", %{env_file: env_file, socket_path: socket_path} do
      result =
        Podman.run_job(
          "alpine:latest",
          "/bin/sh",
          env_file,
          socket_path,
          args: ["-c", "exit 1"]
        )

      assert match?({:status, 1}, result)
    end

    test "mounts socket correctly", %{env_file: env_file, socket_path: socket_path} do
      result =
        Podman.run_job(
          "alpine:latest",
          "/bin/ls",
          env_file,
          socket_path,
          args: ["-la", "/etc/tisktask/command.sock"]
        )

      assert match?({:status, 0}, result)
    end
  end
end
