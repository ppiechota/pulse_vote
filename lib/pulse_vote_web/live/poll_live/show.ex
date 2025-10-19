defmodule PulseVoteWeb.PollLive.Show do
  use PulseVoteWeb, :live_view

  alias PulseVote.Polls

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    poll = Polls.get_poll_with_votes!(id)

    if connected?(socket) do
      Polls.subscribe_to_poll(id)
    end

    {:noreply,
     socket
     |> assign(:page_title, poll.title)
     |> assign(:poll, poll)
     |> assign(:voted, has_voted?(socket, poll))}
  end

  @impl true
  def handle_event("vote", %{"option_id" => option_id}, socket) do
    poll = socket.assigns.poll
    user = socket.assigns.current_user

    case Polls.create_vote(%{
      poll_id: poll.id,
      option_id: option_id,
      user_id: user.id
    }) do
      {:ok, vote} ->
        Polls.broadcast_vote(vote)

        {:noreply,
         socket
         |> assign(:voted, true)
         |> put_flash(:info, "Vote cast successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to cast vote")}
    end
  end

  @impl true
  def handle_info({:vote_cast, _vote}, socket) do
    poll = Polls.get_poll_with_votes!(socket.assigns.poll.id)
    {:noreply, assign(socket, :poll, poll)}
  end

  defp has_voted?(socket, poll) do
    if user = socket.assigns[:current_user] do
      Polls.has_voted?(poll.id, user.id)
    else
      false
    end
  end

  defp total_votes(poll) do
    Enum.sum(Enum.map(poll.options, & &1.vote_count))
  end

  defp percentage(option, total) do
    if total > 0 do
      Float.round(option.vote_count / total * 100, 1)
    else
      0
    end
  end
end