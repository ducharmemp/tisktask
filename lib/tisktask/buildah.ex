defmodule Tisktask.Buildah do
  @moduledoc false
  def build_image(build_context, build_file, tag, into: into) do
    MuonTrap.cmd(
      buildah_exe(),
      [
        "build",
        "-t",
        tag,
        "--layers",
        "-f",
        build_file,
        build_context
      ],
      stderr_to_stdout: true,
      into: into
    )
  end

  defp buildah_exe do
    case System.find_executable("buildah") do
      nil -> raise "Buildah executable not found"
      path -> path
    end
  end
end
