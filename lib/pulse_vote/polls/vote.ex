defmodule PulseVote.Polls.Vote do
  use Ecto.Schema
  import Ecto.Changeset
  alias PulseVote.Polls.Poll

  schema "votes" do
    field :option_id, :string
    field :voter_session_id, :string
    belongs_to :poll, Poll

    timestamps()
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:poll_id, :option_id, :voter_session_id])
    |> validate_required([:poll_id, :option_id, :voter_session_id])
    |> unique_constraint([:poll_id, :voter_session_id])
  end
end