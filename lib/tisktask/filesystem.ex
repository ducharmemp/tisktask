defmodule Tisktask.Filesystem do
  @moduledoc false
  def build_file_for(directory, event) do
    build_files =
      event
      |> parents_of()
      |> Enum.reduce([], fn parent, acc ->
        case safe_wildcard(directory, [parent], "{Dockerfile,Containerfile}*") do
          [] -> acc
          files -> acc ++ files
        end
      end)

    hd(build_files)
  end

  def all_jobs_for(directory, event) do
    directory
    |> safe_wildcard([event], "*")
    |> Enum.reject(fn path ->
      (path |> Path.rootname() |> Path.basename()) in ["Containerfile", "Dockerfile"]
    end)
  end

  defp parents_of(path) do
    path
    |> Path.split()
    |> Enum.reduce(
      [],
      fn segment, acc ->
        case acc do
          [] -> [segment]
          _ -> [acc |> Enum.at(-1) |> Path.join(segment) | acc]
        end
      end
    )
  end

  defp safe_wildcard(directory, subdirs, pattern) when is_list(subdirs) do
    path = Path.join([".tisktask"] ++ subdirs)

    case Path.safe_relative(path, directory) do
      {:ok, sanitized_path} ->
        Path.wildcard(Path.join([directory, sanitized_path, pattern]))

      _ ->
        []
    end
  end
end
