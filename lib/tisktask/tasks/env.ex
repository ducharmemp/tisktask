defmodule Tisktask.Tasks.Env do
  @moduledoc false
  defp new_env_file do
    Path.join(["data", "env", "#{UUID.uuid4(:hex)}.env"])
  end

  def ensure_env_file! do
    tap(new_env_file(), fn path -> File.touch!(path) end)
  end

  def write_env_to(env_file, %{} = env) do
    {:ok, env_file} = Path.safe_relative(env_file)

    env
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(fn [key, value] ->
      [key, String.replace(value, "\n", "\\n")]
    end)
    |> CSV.encode(separator: ?=, delimiter: "\n")
    |> Stream.into(File.stream!(env_file, [:write, :utf8]))
    |> Stream.run()
  end
end
