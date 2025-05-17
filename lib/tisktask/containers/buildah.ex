defmodule Tisktask.Buildah do
  @moduledoc false
  def build_image(build_context, build_file, tag, into: into) do
    [
      buildah_exe(),
      "build",
      "-t",
      tag,
      "--layers",
      "-f",
      build_file,
      build_context
    ]
    |> Exile.stream(stderr: :consume)
    |> Stream.map(fn {_, line} -> line end)
    |> Stream.each(fn
      {:status, _} -> nil
      line -> into.(line)
    end)
    |> Enum.at(-1)
  end

  defp buildah_exe do
    case System.find_executable("buildah") do
      nil -> raise "Buildah executable not found"
      path -> path
    end
  end
end
