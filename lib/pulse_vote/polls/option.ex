defmodule PulseVote.Polls.Option do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :id, :string
    field :text, :string
    field :vote_count, :integer, default: 0
  end

  @doc false
  def changeset(option, attrs) do
    option
    |> cast(attrs, [:id, :text, :vote_count])
    |> validate_required([:text])
    |> validate_length(:text, min: 1, max: 200)
    |> put_id()
  end

  defp put_id(changeset) do
    if get_field(changeset, :id) do
      changeset
    else
      put_change(changeset, :id, Ecto.UUID.generate())
    end
  end
end