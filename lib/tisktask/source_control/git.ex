defmodule Tisktask.Git do
  @moduledoc false
  def clone_at(repo, commit, destination_path, into: into) do
    [
      git_exe(),
      "clone",
      "-c",
      "remote.origin.fetch=+#{commit}:refs/remotes/origin/#{commit}",
      "--no-checkout",
      "--progress",
      "--depth",
      "1",
      repo,
      destination_path
    ]
    |> Exile.stream(stderr: :consume)
    |> Stream.map(fn {_, line} -> line end)
    |> Stream.each(fn
      {:status, _} -> nil
      line -> into.(line)
    end)
    |> Enum.at(-1)
  end

  def checkout(commit, destination_path, into: into) do
    [
      git_exe(),
      "-C",
      destination_path,
      "checkout",
      commit
    ]
    |> Exile.stream(stderr: :consume)
    |> Stream.map(fn {_, line} -> line end)
    |> Stream.each(fn
      {:status, _} -> nil
      line -> into.(line)
    end)
    |> Enum.at(-1)
  end

  defp git_exe do
    case System.find_executable("git") do
      nil -> raise "Git executable not found"
      path -> path
    end
  end
end
