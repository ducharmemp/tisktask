defmodule Tisktask.Containers.Podman do
  @moduledoc false
  def run_job(image, hook_path, env_file, volume, options \\ []) do
    args = Keyword.get(options, :args, [])
    into = Keyword.get(options, :into, fn _ -> nil end)

    [podman_exe()]
    |> Enum.concat(["run", "--rm", "--env-file", env_file])
    |> Enum.concat(["--volume", "#{volume}:/etc/tisktask/command.sock:rw,Z"])
    |> Enum.concat([image, hook_path])
    |> Enum.concat(Enum.map(args, &to_string/1))
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
