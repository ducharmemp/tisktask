defmodule Tisktask.Tasks.Env do
  @moduledoc false
  defp new_env_file do
    env_dir =
      :tisktask
      |> Application.get_env(:state_dir, "data")
      |> Path.join("env")

    File.mkdir_p!(env_dir)
    Path.join(env_dir, "#{UUID.uuid4(:hex)}.env")
  end

  def ensure_env_file! do
    tap(new_env_file(), fn path -> File.touch!(path) end)
  end

  def write_env_to(env_file, %{} = env) do
    env
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(fn [key, value] ->
      [key, encode(value)]
    end)
    |> Enum.into(File.stream!(env_file, [:write, :utf8]), fn [key, value] ->
      "#{key}=#{value}\n"
    end)
    |> Stream.run()
  end

  def encode(value) do
    escaped =
      value
      |> to_string()
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")
      |> String.replace("\n", "\\n")
      |> String.replace("\r", "\\r")

    "\"#{escaped}\""
  end
end
