defmodule Tisktask.EnvTest do
  use ExUnit.Case, async: true

  alias Tisktask.Tasks.Env

  describe "write_env_to/2" do
    test "it writes the env to the file" do
      # Create a temporary file
      {:ok, temp_file} = Briefly.create()
      # Write to the file
      assert :ok = Env.write_env_to(temp_file, %{"TEST_VAR" => "123"})
      # Read the file and check its contents
      assert {:ok, content} = File.read(temp_file)
      assert content == "TEST_VAR=123\n"
    end

    test "it escapes newlines in the env" do
      # Create a temporary file
      {:ok, temp_file} = Briefly.create()
      # Write to the file
      assert :ok = Env.write_env_to(temp_file, %{"TEST_VAR" => "123\n456"})
      # Read the file and check its contents
      assert {:ok, content} = File.read(temp_file)
      assert content == "TEST_VAR=\"123\\n456\"\n"
    end

    test "it quotes the value if it contains spaces" do
      # Create a temporary file
      {:ok, temp_file} = Briefly.create()
      # Write to the file
      assert :ok = Env.write_env_to(temp_file, %{"TEST_VAR" => "123 456"})
      # Read the file and check its contents
      assert {:ok, content} = File.read(temp_file)
      assert content == "TEST_VAR=\"123 456\"\n"
    end

    test "it handles special characters" do
      # Create a temporary file
      {:ok, temp_file} = Briefly.create()
      # Write to the file
      assert :ok = Env.write_env_to(temp_file, %{"TEST_VAR" => "123$%^&*()"})
      # Read the file and check its contents
      assert {:ok, content} = File.read(temp_file)
      assert content == "TEST_VAR=123$%^&*()\n"
    end
  end
end
