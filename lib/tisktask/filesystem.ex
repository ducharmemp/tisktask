defmodule Tisktask.Filesystem do
  @moduledoc false
  def build_file_for(directory, event) do
    search_paths = parents_of(event)

    build_files =
      Enum.reduce(search_paths, [], fn parent, acc ->
        case safe_wildcard(directory, [parent], "{Dockerfile,Containerfile}*") do
          [] -> acc
          files -> acc ++ files
        end
      end)

    case build_files do
      [] ->
        searched = Enum.map(search_paths, &Path.join([directory, ".tisktask", &1]))
        raise "No Dockerfile or Containerfile found. Searched in: #{inspect(searched)}"

      files ->
        hd(files)
    end
  end

  def all_jobs_for(directory, event) do
    directory
    |> safe_wildcard([event], "*")
    |> Enum.reject(fn path ->
      (path |> Path.rootname() |> Path.basename()) in ["Containerfile", "Dockerfile"]
    end)
    |> Enum.map(&Path.relative_to(&1, directory))
  end

  defp parents_of(path) do
    segments =
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

    # Also check the root .tisktask/ directory
    segments ++ [""]
  end

  defp safe_wildcard(directory, subdirs, pattern) when is_list(subdirs) do
    path = Path.join([".tisktask"] ++ subdirs)
    {:ok, sanitized_path} = Path.safe_relative(path, directory)
    Path.wildcard(Path.join([directory, sanitized_path, pattern]))
  end
end
