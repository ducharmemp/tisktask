defmodule Tisktask.Containers.Buildah do
  @moduledoc false
  def build_image(build_context, build_file, tag, into: into) do
    {output, exit_status} =
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
      |> Enum.reduce({[], nil}, fn
        {:status, status}, {output, _} ->
          {output, status}

        {_, line}, {output, status} ->
          into.(line)
          {[line | output], status}
      end)

    case exit_status do
      0 -> {:ok, tag}
      _ -> {:error, output |> Enum.reverse() |> Enum.join("\n")}
    end
  end

  defp buildah_exe do
    case System.find_executable("buildah") do
      nil -> raise "Buildah executable not found"
      path -> path
    end
  end
end
