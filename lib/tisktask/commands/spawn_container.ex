defmodule Tisktask.Commands.SpawnContainer do
  @moduledoc false
  alias Tisktask.Containers.Podman
  alias Tisktask.Tasks.Env

  @command "SPAWNCONTAINER"

  def name, do: @command

  def command(_run, job, [image | env_args]) do
    env_file =
      case parse_env_args(env_args) do
        [] ->
          nil

        env_vars ->
          env_file = Env.ensure_env_file!()
          Env.write_env_to(env_file, Map.new(env_vars))
          env_file
      end

    Podman.run_sidecar(job.pod_id, image, env_file)
    {:reply, :ok}
  end

  def command(_run, _job, _args) do
    {:reply, {:error, "usage: SPAWNCONTAINER <image> [KEY=value ...]"}}
  end

  defp parse_env_args(args) do
    Enum.flat_map(args, fn arg ->
      case String.split(arg, "=", parts: 2) do
        [key, value] -> [{key, value}]
        _ -> []
      end
    end)
  end
end
