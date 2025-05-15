defmodule Tisktask.PubSub do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def subscribe_to(item, events \\ ["created", "updated", "deleted"])

      def subscribe_to(item, events) when is_atom(item) do
        for event <- events do
          topic = "#{name_for(item)}:#{event}"
          Phoenix.PubSub.subscribe(Tisktask.PubSub, topic)
        end

        item
      end

      def subscribe_to(item, events) when is_list(events) do
        for event <- events do
          subscribe_to(item, event)
        end

        item
      end

      def subscribe_to(item, event) do
        topic = "#{name_for(item)}:#{event}:#{item.id}"
        Phoenix.PubSub.subscribe(Tisktask.PubSub, topic)
        item
      end

      def publish({:ok, item}, event) do
        publish(item, event)
        {:ok, item}
      end

      def publish({:error, item}, event) do
        {:error, item}
      end

      def publish(item, child, event) do
        topic = "#{name_for(item)}:#{event}:#{item.id}"
        Phoenix.PubSub.broadcast(Tisktask.PubSub, topic, {topic, item, child})
        item
      end

      def publish(item, event) do
        topic = "#{name_for(item)}:#{event}:#{item.id}"
        Phoenix.PubSub.broadcast(Tisktask.PubSub, topic, {topic, item})
        topic = "#{name_for(item)}:#{event}"
        Phoenix.PubSub.broadcast(Tisktask.PubSub, topic, {topic, item.id})
        item
      end

      defp name_for(%{__struct__: struct}) do
        struct.__schema__(:source)
      end

      defp name_for(item) when is_atom(item) do
        item.__schema__(:source)
      end
    end
  end
end
