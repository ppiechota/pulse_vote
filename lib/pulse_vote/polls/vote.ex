defmodule PulseVote.Polls.Vote do
  use Ecto.Schema
  import Ecto.Changeset
  alias PulseVote.Polls.Poll
  alias PulseVote.Accounts.User

  schema "votes" do
    field :option_id, :string
    belongs_to :poll, Poll
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:poll_id, :option_id, :user_id])
    |> validate_required([:poll_id, :option_id, :user_id])
    |> unique_constraint([:poll_id, :user_id])
  end
end