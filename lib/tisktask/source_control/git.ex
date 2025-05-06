defmodule Tisktask.Git do
  @moduledoc false
  def clone_at(repo, commit, destination_path, into: into) do
    MuonTrap.cmd(
      git_exe(),
      [
        "clone",
        "-c",
        "remote.origin.fetch=+#{commit}:refs/remotes/origin/#{commit}",
        "--no-checkout",
        "--progress",
        "--depth",
        "1",
        repo,
        destination_path
      ],
      into: into,
      stderr_to_stdout: true
    )
  end

  def checkout(commit, destination_path, into: into) do
    MuonTrap.cmd(
      git_exe(),
      [
        "-C",
        destination_path,
        "checkout",
        commit
      ],
      into: into,
      stderr_to_stdout: true
    )
  end

  defp git_exe do
    case System.find_executable("git") do
      nil -> raise "Git executable not found"
      path -> path
    end
  end
end
