defmodule Tisktask.Containers.Podman do
  @moduledoc false
  def run_job(image, hook_path, env_file, volume, options \\ []) do
    args = Keyword.get(options, :args, [])
    into = Keyword.get(options, :into, fn _ -> nil end)

    {pod_id, 0} = System.cmd(podman_exe(), ["pod", "create"], stderr_to_stdout: true)
    pod_id = String.trim(pod_id)

    {_, 0} =
      ["create", "--rm", "--env-file", env_file, "--pod", pod_id]
      |> Enum.concat()
      |> Enum.concat(["--volume", "#{volume}:/etc/tisktask/command.sock:rw,Z"])
      |> Enum.concat([image, hook_path])
      |> Enum.concat(Enum.map(args, &to_string/1))
      |> System.cmd(podman_exe(), &1, stderr_to_stdout: true)

    {_, 0} = System.cmd(podman_exe(), ["pod", "start", pod_id], stderr_to_stdout: true)

    [podman_exe(), "pod", "logs", "-f", pod_id]
    |> Exile.stream(stderr: :consume, ignore_epipe: true)
    |> Stream.map(fn {_, line} -> line end)
    |> Stream.each(fn
      {:status, _} -> nil
      line -> into.(line)
    end)
    |> Enum.at(-1)
  end

  defp podman_exe do
    case System.find_executable("podman") do
      nil -> raise "Podman executable not found"
      path -> path
    end
  end
end
