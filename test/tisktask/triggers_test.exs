defmodule Tisktask.TriggersTest do
  use Tisktask.DataCase, async: true

  alias Tisktask.Triggers

  describe "repository_for/1" do
    test "returns repository when github_repository_id is nil" do
      repository = insert(:github_repository)

      trigger =
        build(:github_trigger,
          github_repository_id: nil,
          source_control_repository_id: repository.id
        )

      assert Triggers.repository_for(trigger) == repository
    end

    test "returns repository when github_repository_id is present" do
      repository = insert(:github_repository, external_repository_id: 123)

      trigger =
        build(:github_trigger,
          github_repository_id: 123
        )

      assert Triggers.repository_for(trigger) == repository
    end
  end

  describe "env_for/1" do
    test "returns correct environment variables" do
      repository = insert(:github_repository)

      trigger =
        insert(:github_trigger,
          type: "push",
          action: "created",
          source_control_repository: repository,
          payload: %{"after" => "abc123"}
        )

      env = Triggers.env_for(trigger)

      assert env == %{
               CI: "true",
               TISKTASK_GITHUB_EVENT: "push",
               TISKTASK_GITHUB_ACTION: "created",
               TISKTASK_GITHUB_SHA: "abc123",
               TISKTASK_GITHUB_REPOSITORY: repository.name
             }
    end
  end

  describe "head_sha/1" do
    test "returns the after value from payload" do
      trigger =
        build(:github_trigger,
          payload: %{"after" => "abc123"}
        )

      assert Triggers.head_sha(trigger) == "abc123"
    end
  end

  describe "type/1" do
    test "joins type and action" do
      trigger =
        build(:github_trigger,
          type: "push",
          action: "created"
        )

      assert Triggers.type(trigger) == "push/created"
    end
  end

  describe "update_remote_status/3" do
    test "sends correct request to update status" do
      Req.Test.stub(Triggers, &Plug.Conn.send_resp(&1, 201, ""))

      repository =
        insert(:github_repository,
          api_token: "test-token",
          raw_attributes: %{
            "statuses_url" => "https://api.github.com/repos/owner/repo/statuses/{sha}"
          }
        )

      trigger =
        insert(:github_trigger,
          source_control_repository: repository,
          payload: %{"after" => "abc123"}
        )

      response = Triggers.update_remote_status(trigger, "test-status", "success")
      assert response.status == 201
    end
  end
end
