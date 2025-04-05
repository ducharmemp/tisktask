defmodule Tisktask.Filesystem do
  @moduledoc false
  def build_file_for(directory, event) do
    event_specific_build_files =
      Path.wildcard(Path.join([directory, ".tisktask", event, "{Dockerfile,Containerfile}*"]))

    generic_build_files =
      Path.wildcard(Path.join([directory, ".tisktask", "{Dockerfile,Containerfile}*"]))

    build_files =
      if event_specific_build_files == [] do
        generic_build_files
      else
        event_specific_build_files
      end

    build_files |> Enum.sort() |> List.first() |> Path.relative_to(directory)
  end

  def all_jobs_for(directory, event) do
    [directory, ".tisktask", event, "*"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.reject(fn path ->
      (path |> Path.rootname() |> Path.basename()) in ["Containerfile", "Dockerfile"]
    end)
    |> Enum.map(fn path ->
      Path.relative_to(path, directory)
    end)
  end
end
