defmodule Tisktask.Containers.Podman do
  @moduledoc false

  def create_pod do
    {pod_id, 0} = System.cmd(podman_exe(), ["pod", "create", "--exit-policy=stop"], stderr_to_stdout: true)
    String.trim(pod_id)
  end

  def create_container(pod_id, image, hook_path, env_file, volume, args \\ []) do
    {container_id, 0} =
      ["create", "--env-file", env_file, "--pod", pod_id]
      |> Enum.concat(["--volume", "#{volume}:/etc/tisktask/command.sock:rw,Z"])
      |> Enum.concat([image, hook_path])
      |> Enum.concat(Enum.map(args, &to_string/1))
      |> then(&System.cmd(podman_exe(), &1, stderr_to_stdout: true))

    String.trim(container_id)
  end

  def start_pod(pod_id) do
    {_, 0} = System.cmd(podman_exe(), ["pod", "start", pod_id], stderr_to_stdout: true)
    :ok
  end

  def run_sidecar(pod_id, image, env_file \\ nil) do
    args = ["run", "-d", "--pod", pod_id]
    args = if env_file, do: args ++ ["--env-file", env_file], else: args

    {container_id, 0} =
      System.cmd(podman_exe(), args ++ [image], stderr_to_stdout: true)

    String.trim(container_id)
  end

  def stream_logs(pod_id, into) do
    [podman_exe(), "pod", "logs", "-f", pod_id]
    |> Exile.stream(stderr: :consume, ignore_epipe: true)
    |> Stream.map(fn {_, line} -> line end)
    |> Enum.each(fn
      {:status, _} -> nil
      line -> into.(line)
    end)
  end

  def wait_for_container(container_id) do
    {exit_code_str, 0} = System.cmd(podman_exe(), ["wait", container_id])
    exit_code_str |> String.trim() |> String.to_integer()
  end

  def cleanup(pod_id, container_id) do
    System.cmd(podman_exe(), ["rm", container_id])
    System.cmd(podman_exe(), ["pod", "stop", pod_id])
    System.cmd(podman_exe(), ["pod", "rm", pod_id])
    :ok
  end

  defp podman_exe do
    case System.find_executable("podman") do
      nil -> raise "Podman executable not found"
      path -> path
    end
  end
end
