defmodule Tisktask.Podman do
  @moduledoc false
  def run_job(image, hook_path, env_file, into: into) do
    MuonTrap.cmd(podman_exe(), ["run", "--rm", "--env-file", env_file, image, hook_path],
      stderr_to_stdout: true,
      into: into
    )
  end

  defp podman_exe do
    case System.find_executable("podman") do
      nil -> raise "Podman executable not found"
      path -> path
    end
  end
end
