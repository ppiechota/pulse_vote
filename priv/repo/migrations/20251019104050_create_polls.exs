defmodule PulseVote.Repo.Migrations.CreatePolls do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :title, :string, null: false
      add :description, :text
      add :options, :jsonb, null: false, default: "[]"

      timestamps()
    end

    create index(:polls, [:inserted_at])
  end
end
