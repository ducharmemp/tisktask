defmodule Tisktask.Filesystem do
  @moduledoc false
  def build_file_for(directory, event) do
    event_specific_build_files =
      safe_wildcard(directory, [event], "{Dockerfile,Containerfile}*")

    generic_build_files = safe_wildcard(directory, [], "{Dockerfile,Containerfile}*")

    build_files =
      if event_specific_build_files == [] do
        generic_build_files
      else
        event_specific_build_files
      end

    build_files |> Enum.sort() |> List.first()
  end

  def all_jobs_for(directory, event) do
    safe_wildcard(directory, [event], "*")
    |> Enum.reject(fn path ->
      (path |> Path.rootname() |> Path.basename()) in ["Containerfile", "Dockerfile"]
    end)
    |> dbg()
  end

  defp safe_wildcard(directory, subdirs, pattern) when is_list(subdirs) do
    with path <- Path.join([".tisktask"] ++ subdirs),
         {:ok, sanitized_path} <- Path.safe_relative(path, directory) do
      Path.wildcard(Path.join(sanitized_path, pattern))
    else
      _ ->
        []
    end
  end
end
