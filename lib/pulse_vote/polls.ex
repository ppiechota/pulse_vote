defmodule PulseVote.Polls do
  @moduledoc """
  The Polls context.
  """

  import Ecto.Query, warn: false
  alias PulseVote.Repo
  alias PulseVote.Polls.{Poll, Vote}

  @doc """
  Returns the list of polls.
  """
  def list_polls do
    Poll
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single poll.
  Raises `Ecto.NoResultsError` if the Poll does not exist.
  """
  def get_poll!(id), do: Repo.get!(Poll, id)

  @doc """
  Gets a poll with aggregated vote counts.
  """
  def get_poll_with_votes!(id) do
    poll = get_poll!(id)
    votes = get_votes_by_poll(id)

    # Count votes for each option
    vote_counts = Enum.frequencies_by(votes, & &1.option_id)

    # Update option vote counts
    options = Enum.map(poll.options, fn option ->
      %{option | vote_count: Map.get(vote_counts, option.id, 0)}
    end)

    %{poll | options: options}
  end

  @doc """
  Creates a poll.
  """
  def create_poll(attrs \\ %{}) do
    %Poll{}
    |> Poll.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a poll.
  """
  def update_poll(%Poll{} = poll, attrs) do
    poll
    |> Poll.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a poll.
  """
  def delete_poll(%Poll{} = poll) do
    Repo.delete(poll)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking poll changes.
  """
  def change_poll(%Poll{} = poll, attrs \\ %{}) do
    Poll.changeset(poll, attrs)
  end

  # Votes

  @doc """
  Creates a vote for a poll option.
  """
  def create_vote(attrs \\ %{}) do
    %Vote{}
    |> Vote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets all votes for a specific poll.
  """
  def get_votes_by_poll(poll_id) do
    Vote
    |> where([v], v.poll_id == ^poll_id)
    |> Repo.all()
  end

  @doc """
  Checks if a user has already voted on a poll.
  """
  def has_voted?(poll_id, user_id) do
    Vote
    |> where([v], v.poll_id == ^poll_id and v.user_id == ^user_id)
    |> Repo.exists?()
  end

  @doc """
  Gets a vote by poll_id and user_id.
  """
  def get_vote_by_user(poll_id, user_id) do
    Vote
    |> where([v], v.poll_id == ^poll_id and v.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Subscribes to poll updates for real-time updates.
  """
  def subscribe_to_poll(poll_id) do
    Phoenix.PubSub.subscribe(PulseVote.PubSub, "poll:#{poll_id}")
  end

  @doc """
  Broadcasts a vote update to all subscribers.
  """
  def broadcast_vote(%Vote{} = vote) do
    Phoenix.PubSub.broadcast(
      PulseVote.PubSub,
      "poll:#{vote.poll_id}",
      {:vote_cast, vote}
    )
  end
end