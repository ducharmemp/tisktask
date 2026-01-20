defmodule Tisktask.Containers.BuildahTest do
  use ExUnit.Case

  alias Tisktask.Containers.Buildah

  # Add integration tag since we're interacting with system commands
  @moduletag :integration

  setup do
    # Create a temporary build context
    {:ok, build_context} = Briefly.create(directory: true)

    # Create a test Dockerfile
    dockerfile_path = Path.join(build_context, "Dockerfile")

    File.write!(dockerfile_path, """
    FROM alpine:latest
    RUN echo "test" > /test.txt
    """)

    {:ok, %{build_context: build_context, dockerfile: "Dockerfile"}}
  end

  describe "build_image/4" do
    test "successfully builds an image", %{build_context: context, dockerfile: dockerfile} do
      # Collect output lines in a list for verification
      output_lines = []
      collector = fn line -> output_lines ++ [line] end

      result =
        Buildah.build_image(
          context,
          dockerfile,
          "test-image:latest",
          into: collector
        )

      assert result == {:status, 0}
    end

    test "streams build output to callback", %{build_context: context, dockerfile: dockerfile} do
      # Create an agent to collect output lines
      {:ok, agent} = Agent.start_link(fn -> [] end)

      collector = fn line ->
        Agent.update(agent, fn lines -> [line | lines] end)
      end

      Buildah.build_image(
        context,
        dockerfile,
        "test-image:latest",
        into: collector
      )

      # Get collected output
      output = Agent.get(agent, fn lines -> Enum.reverse(lines) end)

      # Verify we got some output
      assert length(output) > 0

      # Cleanup
      Agent.stop(agent)
    end
  end
end
