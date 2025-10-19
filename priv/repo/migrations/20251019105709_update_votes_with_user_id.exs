defmodule PulseVote.Repo.Migrations.UpdateVotesWithUserId do
  use Ecto.Migration

  def change do
    drop_if_exists index(:votes, [:voter_session_id])
    drop_if_exists unique_index(:votes, [:poll_id, :voter_session_id])

    alter table(:votes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      remove :voter_session_id
    end

    create index(:votes, [:user_id])
    create unique_index(:votes, [:poll_id, :user_id])
  end
end
