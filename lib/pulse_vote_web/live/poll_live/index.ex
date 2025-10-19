defmodule PulseVoteWeb.PollLive.Index do
  use PulseVoteWeb, :live_view

  alias PulseVote.Polls
  alias PulseVote.Polls.Poll

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, polls: Polls.list_polls())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Poll")
    |> assign(:poll, %Poll{options: [%{text: ""}, %{text: ""}]})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Polls")
    |> assign(:poll, nil)
  end

  @impl true
  def handle_info({PulseVoteWeb.PollLive.FormComponent, {:saved, _poll}}, socket) do
    # Refresh the polls list after creating a new poll
    {:noreply, assign(socket, polls: Polls.list_polls())}
  end
end