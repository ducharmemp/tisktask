defmodule Tisktask.EnvTest do
  use ExUnit.Case, async: true

  alias Tisktask.Tasks.Env

  describe "write_env_to/2" do
    test "it writes the env to the file" do
      {:ok, temp_file} = Briefly.create()
      assert :ok = Env.write_env_to(temp_file, %{"TEST_VAR" => "123"})
      assert {:ok, content} = File.read(temp_file)
      assert content == "TEST_VAR=\"123\"\n"
    end

    test "it quotes the value if it contains spaces" do
      {:ok, temp_file} = Briefly.create()
      assert :ok = Env.write_env_to(temp_file, %{"TEST_VAR" => "123 456"})
      assert {:ok, content} = File.read(temp_file)
      assert content == "TEST_VAR=\"123 456\"\n"
    end

    test "it handles special characters" do
      {:ok, temp_file} = Briefly.create()
      assert :ok = Env.write_env_to(temp_file, %{"TEST_VAR" => "123$%^&*()"})
      assert {:ok, content} = File.read(temp_file)
      assert content == "TEST_VAR=\"123$%^&*()\"\n"
    end

    test "it handles backslashes" do
      {:ok, temp_file} = Briefly.create()
      assert :ok = Env.write_env_to(temp_file, %{"TEST_VAR" => "123\\456"})
      assert {:ok, content} = File.read(temp_file)
      assert content == "TEST_VAR=\"123\\\\456\"\n"
    end
  end
end
