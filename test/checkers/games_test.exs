defmodule Checkers.GamesTest do
  use Checkers.DataCase

  alias Checkers.Games

  describe "matches" do
    alias Checkers.Games.Match

    @valid_attrs %{board: "some board", extra_turn: "some extra_turn"}
    @update_attrs %{board: "some updated board", extra_turn: "some updated extra_turn"}
    @invalid_attrs %{board: nil, extra_turn: nil}

    def match_fixture(attrs \\ %{}) do
      {:ok, match} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Games.create_match()

      match
    end

    test "list_matches/0 returns all matches" do
      match = match_fixture()
      assert Games.list_matches() == [match]
    end

    test "get_match!/1 returns the match with given id" do
      match = match_fixture()
      assert Games.get_match!(match.id) == match
    end

    test "create_match/1 with valid data creates a match" do
      assert {:ok, %Match{} = match} = Games.create_match(@valid_attrs)
      assert match.board == "some board"
      assert match.extra_turn == "some extra_turn"
    end

    test "create_match/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_match(@invalid_attrs)
    end

    test "update_match/2 with valid data updates the match" do
      match = match_fixture()
      assert {:ok, %Match{} = match} = Games.update_match(match, @update_attrs)
      assert match.board == "some updated board"
      assert match.extra_turn == "some updated extra_turn"
    end

    test "update_match/2 with invalid data returns error changeset" do
      match = match_fixture()
      assert {:error, %Ecto.Changeset{}} = Games.update_match(match, @invalid_attrs)
      assert match == Games.get_match!(match.id)
    end

    test "delete_match/1 deletes the match" do
      match = match_fixture()
      assert {:ok, %Match{}} = Games.delete_match(match)
      assert_raise Ecto.NoResultsError, fn -> Games.get_match!(match.id) end
    end

    test "change_match/1 returns a match changeset" do
      match = match_fixture()
      assert %Ecto.Changeset{} = Games.change_match(match)
    end
  end
end
