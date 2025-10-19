defmodule PulseVoteWeb.PollLive.Show do
  use PulseVoteWeb, :live_view

  alias PulseVote.Polls

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => "new"}, _, socket) do
    poll = %Polls.Poll{options: [%Polls.Option{}, %Polls.Option{}]}
    changeset = Polls.change_poll(poll)

    {:noreply,
     socket
     |> assign(:page_title, "Create New Poll")
     |> assign(:poll, poll)
     |> assign(:form, to_form(changeset))
     |> assign(:mode, :new)}
  end

  def handle_params(%{"id" => id}, _, socket) do
    poll = Polls.get_poll_with_votes!(id)

    if connected?(socket) do
      Polls.subscribe_to_poll(id)
    end

    {:noreply,
     socket
     |> assign(:page_title, poll.title)
     |> assign(:poll, poll)
     |> assign(:voted, has_voted?(socket, poll))
     |> assign(:mode, :show)}
  end

  @impl true
  def handle_event("validate", %{"poll" => poll_params}, socket) do
    changeset =
      socket.assigns.poll
      |> Polls.change_poll(poll_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"poll" => poll_params}, socket) do
    user = socket.assigns.current_user
    poll_params = Map.put(poll_params, "user_id", user.id)

    case Polls.create_poll(poll_params) do
      {:ok, poll} ->
        {:noreply,
         socket
         |> put_flash(:info, "Poll created successfully!")
         |> push_navigate(to: ~p"/polls/#{poll.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("add_option", _params, socket) do
    existing_options = Ecto.Changeset.get_field(socket.assigns.form.source, :options, [])
    new_options = existing_options ++ [%Polls.Option{}]

    changeset =
      socket.assigns.poll
      |> Polls.change_poll(%{options: new_options})
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("remove_option", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    existing_options = Ecto.Changeset.get_field(socket.assigns.form.source, :options, [])
    new_options = List.delete_at(existing_options, index)

    changeset =
      socket.assigns.poll
      |> Polls.change_poll(%{options: new_options})
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

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