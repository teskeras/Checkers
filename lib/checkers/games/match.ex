defmodule Checkers.Games.Match do
  use Ecto.Schema
  import Ecto.Changeset

  schema "matches" do
    field :board, :string
    field :extra_turn, :string
    field :white_id, :id
    field :black_id, :id
    field :turn_id, :id
    field :winner_id, :id

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:board, :extra_turn, :white_id, :black_id, :turn_id, :winner_id])
    |> validate_required([:board, :extra_turn])
  end
end
