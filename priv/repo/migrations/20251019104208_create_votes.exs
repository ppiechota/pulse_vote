defmodule PulseVote.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :poll_id, references(:polls, on_delete: :delete_all), null: false
      add :option_id, :string, null: false
      add :voter_session_id, :string, null: false

      timestamps()
    end

    create index(:votes, [:poll_id])
    create index(:votes, [:voter_session_id])
    create unique_index(:votes, [:poll_id, :voter_session_id])
  end
end
