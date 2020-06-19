defmodule Checkers.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :board, :string
      add :extra_turn, :string
      add :white_id, references(:users, on_delete: :nothing)
      add :black_id, references(:users, on_delete: :nothing)
      add :turn_id, references(:users, on_delete: :nothing)
      add :winner_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:matches, [:white_id])
    create index(:matches, [:black_id])
    create index(:matches, [:turn_id])
    create index(:matches, [:winner_id])
  end
end
