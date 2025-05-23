defmodule Tisktask.FilesystemTest do
  use ExUnit.Case

  alias Tisktask.Filesystem

  setup do
    {:ok, temp_dir} = Briefly.create(directory: true)
    {:ok, dir: temp_dir}
  end

  describe "build_file_for/2" do
    test "finds Dockerfile in event-specific directories first", %{dir: dir} do
      event_path = "feature/test"
      dockerfile_path = Path.join([dir, ".tisktask", "feature", "Dockerfile"])

      File.mkdir_p!(Path.dirname(dockerfile_path))
      File.write!(dockerfile_path, "FROM alpine")

      dockerfile_path = Path.join([dir, ".tisktask", "feature", "test", "Dockerfile"])

      File.mkdir_p!(Path.dirname(dockerfile_path))
      File.write!(dockerfile_path, "FROM alpine")
      Filesystem.build_file_for(dir, event_path)
      assert Filesystem.build_file_for(dir, event_path) == dockerfile_path
    end

    test "finds Containerfile in event-specific directories first", %{dir: dir} do
      event_path = "feature/test"
      containerfile_path = Path.join([dir, ".tisktask", "feature", "Containerfile"])

      File.mkdir_p!(Path.dirname(containerfile_path))
      File.write!(containerfile_path, "FROM alpine")

      containerfile_path = Path.join([dir, ".tisktask", "feature", "test", "Containerfile"])

      File.mkdir_p!(Path.dirname(containerfile_path))
      File.write!(containerfile_path, "FROM alpine")

      assert Filesystem.build_file_for(dir, event_path) == containerfile_path
    end

    test "finds Dockerfile in parent directories", %{dir: dir} do
      event_path = "feature/test"
      dockerfile_path = Path.join([dir, ".tisktask", "feature", "Dockerfile"])

      File.mkdir_p!(Path.dirname(dockerfile_path))
      File.write!(dockerfile_path, "FROM alpine")

      assert Filesystem.build_file_for(dir, event_path) == dockerfile_path
    end

    test "finds Containerfile in parent directories", %{dir: dir} do
      event_path = "feature/test"
      containerfile_path = Path.join([dir, ".tisktask", "feature", "Containerfile"])

      File.mkdir_p!(Path.dirname(containerfile_path))
      File.write!(containerfile_path, "FROM alpine")

      assert Filesystem.build_file_for(dir, event_path) == containerfile_path
    end
  end

  describe "all_jobs_for/2" do
    test "finds all job files except Dockerfile/Containerfile", %{dir: dir} do
      event_path = "feature"
      base_path = Path.join([dir, ".tisktask", event_path])

      File.mkdir_p!(base_path)
      File.write!(Path.join(base_path, "Dockerfile"), "")
      File.write!(Path.join(base_path, "test.sh"), "")
      File.write!(Path.join(base_path, "lint.sh"), "")

      jobs = Filesystem.all_jobs_for(dir, event_path)

      assert length(jobs) == 2
      assert Enum.all?(jobs, &String.ends_with?(&1, ".sh"))
      refute Enum.any?(jobs, &String.ends_with?(&1, "Dockerfile"))
    end
  end
end
