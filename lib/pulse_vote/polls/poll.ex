defmodule PulseVote.Polls.Poll do
  use Ecto.Schema
  import Ecto.Changeset
  alias PulseVote.Polls.Option

  schema "polls" do
    field :title, :string
    field :description, :string
    embeds_many :options, Option, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(poll, attrs) do
    poll
    |> cast(attrs, [:title, :description])
    |> cast_embed(:options, required: true, with: &Option.changeset/2)
    |> validate_required([:title])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:description, max: 500)
    |> validate_length(:options, min: 2, max: 10)
  end
end