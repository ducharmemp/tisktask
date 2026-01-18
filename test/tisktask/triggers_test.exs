defmodule Tisktask.TriggersTest do
  use Tisktask.DataCase, async: true

  alias Tisktask.Triggers

  describe "create_trigger/1" do
    test "creates trigger and associates repository by external_repository_id" do
      repository = insert(:source_control_repository, external_repository_id: 12_345)

      attrs = %{
        provider: "github",
        type: "push",
        action: "created",
        payload: %{"after" => "abc123"},
        repository_id: 12_345
      }

      assert {:ok, trigger} = Triggers.create_trigger(attrs)
      assert trigger.source_control_repository_id == repository.id
    end

    test "returns error when repository not found" do
      attrs = %{
        provider: "github",
        type: "push",
        action: "created",
        payload: %{"after" => "abc123"},
        repository_id: 99_999
      }

      assert {:error, :repository_not_found} = Triggers.create_trigger(attrs)
    end
  end

  describe "repository_for/1" do
    test "returns repository for persisted trigger" do
      repository = insert(:source_control_repository)
      trigger = insert(:trigger, source_control_repository: repository)

      assert Triggers.repository_for(trigger) == repository
    end
  end

  describe "env_for/1" do
    test "returns correct environment variables for github" do
      repository = insert(:source_control_repository)

      trigger =
        insert(:trigger,
          provider: "github",
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

    test "returns correct environment variables for forgejo" do
      repository = insert(:source_control_repository)

      trigger =
        insert(:trigger,
          provider: "forgejo",
          type: "push",
          action: "created",
          source_control_repository: repository,
          payload: %{"after" => "abc123"}
        )

      env = Triggers.env_for(trigger)

      assert env == %{
               CI: "true",
               TISKTASK_FORGEJO_EVENT: "push",
               TISKTASK_FORGEJO_ACTION: "created",
               TISKTASK_FORGEJO_SHA: "abc123",
               TISKTASK_FORGEJO_REPOSITORY: repository.name
             }
    end
  end

  describe "head_sha/1" do
    test "returns the after value from payload" do
      trigger =
        build(:trigger,
          payload: %{"after" => "abc123"}
        )

      assert Triggers.head_sha(trigger) == "abc123"
    end
  end

  describe "type/1" do
    test "joins type and action" do
      trigger =
        build(:trigger,
          type: "push",
          action: "created"
        )

      assert Triggers.type(trigger) == "push/created"
    end
  end

  describe "update_remote_status/4" do
    test "sends correct request to update status" do
      Req.Test.stub(Triggers, &Plug.Conn.send_resp(&1, 201, ""))

      repository =
        insert(:source_control_repository,
          api_token: "test-token",
          raw_attributes: %{
            "statuses_url" => "https://api.github.com/repos/owner/repo/statuses/{sha}"
          }
        )

      trigger =
        insert(:trigger,
          source_control_repository: repository,
          payload: %{"after" => "abc123"}
        )

      response = Triggers.update_remote_status(trigger, 123, "test-status", "success")
      assert response.status == 201
    end
  end
end
