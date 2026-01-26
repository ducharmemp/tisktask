defmodule Tisktask.TaskLogsTest do
  use ExUnit.Case, async: false

  alias Tisktask.TaskLogs
  alias Tisktask.Tasks.Job

  setup do
    {:ok, temp_dir} = Briefly.create(directory: true)
    original_state_dir = Application.get_env(:tisktask, :state_dir)
    Application.put_env(:tisktask, :state_dir, temp_dir)

    on_exit(fn ->
      if original_state_dir do
        Application.put_env(:tisktask, :state_dir, original_state_dir)
      else
        Application.delete_env(:tisktask, :state_dir)
      end
    end)

    {:ok, state_dir: temp_dir, logs_dir: Path.join(temp_dir, "logs")}
  end

  describe "ensure_log_file!/0" do
    test "creates a log file in the logs directory", %{logs_dir: logs_dir} do
      log_file = TaskLogs.ensure_log_file!()

      assert String.starts_with?(log_file, logs_dir)
      assert String.ends_with?(log_file, ".log")
      assert File.exists?(Path.dirname(log_file))
    end

    test "creates unique log files on each call", %{logs_dir: logs_dir} do
      log_file1 = TaskLogs.ensure_log_file!()
      log_file2 = TaskLogs.ensure_log_file!()

      assert log_file1 != log_file2
      assert String.starts_with?(log_file1, logs_dir)
      assert String.starts_with?(log_file2, logs_dir)
    end
  end

  describe "stream_to/1" do
    test "returns a writer function" do
      log_file = TaskLogs.ensure_log_file!()
      loggable = %Job{log_file: log_file}

      writer = TaskLogs.stream_to(loggable)

      assert is_function(writer, 1)
    end
  end

  describe "stream_from!/1" do
    test "reads log entries with timestamps and content" do
      log_file = TaskLogs.ensure_log_file!()
      loggable = %Job{log_file: log_file}

      # Write log lines in the expected format
      File.write!(log_file, """
      2024-01-25T12:00:00.000000Z first line
      2024-01-25T12:00:01.000000Z second line
      """)

      logs = TaskLogs.stream_from!(loggable) |> Enum.to_list()

      assert length(logs) == 2
      assert Enum.at(logs, 0).id == "2024-01-25T12:00:00.000000Z"
      assert Enum.at(logs, 0).log == "first line"
      assert Enum.at(logs, 1).id == "2024-01-25T12:00:01.000000Z"
      assert Enum.at(logs, 1).log == "second line"
    end

    test "handles log lines with spaces in content" do
      log_file = TaskLogs.ensure_log_file!()
      loggable = %Job{log_file: log_file}

      File.write!(log_file, "2024-01-25T12:00:00.000000Z line with multiple spaces\n")

      [log_entry] = TaskLogs.stream_from!(loggable) |> Enum.to_list()

      assert log_entry.log == "line with multiple spaces"
    end

    test "filters out malformed log lines without timestamp separator" do
      log_file = TaskLogs.ensure_log_file!()
      loggable = %Job{log_file: log_file}

      File.write!(log_file, """
      malformed_line_without_space
      2024-01-25T12:00:00.000000Z valid line
      another_malformed_line
      """)

      logs = TaskLogs.stream_from!(loggable) |> Enum.to_list()

      assert length(logs) == 1
      assert Enum.at(logs, 0).log == "valid line"
    end

    test "handles empty log file" do
      log_file = TaskLogs.ensure_log_file!()
      loggable = %Job{log_file: log_file}

      # Create an empty file
      File.write!(log_file, "")

      logs = TaskLogs.stream_from!(loggable) |> Enum.to_list()

      assert logs == []
    end
  end
end
