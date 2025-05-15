defmodule Tisktask.Podman do
  @moduledoc false
  def run_job(image, hook_path, env_file, into: into) do
    [podman_exe(), "run", "--rm", "--env-file", env_file, image, hook_path]
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
