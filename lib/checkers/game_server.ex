defmodule Checkers.GameServer do
  use GenServer

  alias Checkers.Games

  def create_match(white_id, black_id) do
    # IO.puts("Creating game: " <> white_id <> " vs " <> black_id)
    Games.create_match(%{white_id: white_id, black_id: black_id, turn_id: white_id, extra_turn: no_extra_turn(), board: initial_board()})
  end

  def surrender(match_id, user_id) do
    match = Games.get_match!(match_id)
    cond do
      user_id == match.white_id ->
        Games.update_match(match, %{winner_id: match.black_id})

      user_id == match.black_id ->
        Games.update_match(match, %{winner_id: match.white_id})

      true -> {:error, :user_not_in_match}
    end
  end

  def move(match_id, user_id, old_coord, new_coord) do
    match = Games.get_match!(match_id)
    # board_map = get_board_map(match.board)
    {pawn, king, my_id, enemy_pawn, enemy_king, enemy_id} = if user_id == match.white_id do
      {white_pawn(), white_king(), match.white_id, black_pawn(), black_king(), match.black_id}
    else
      {black_pawn(), black_king(), match.black_id, white_pawn(), white_king(), match.white_id}
    end
    cond do
      user_id != match.white_id && user_id != match.black_id ->
        {:error, :user_not_in_match}

      user_id != match.turn_id ->
        {:error, :not_your_turn}

      old_coord.x < 0 || old_coord.x > 7 || old_coord.y < 0 || old_coord.y > 7 || new_coord.x < 0 || new_coord.x > 7 || new_coord.y < 0 || new_coord.y > 7 ->
        {:error, :coordinates_out_of_bounds}

      match.extra_turn != no_extra_turn() && match.extra_turn != to_string(old_coord.x) <> to_string(old_coord.y) ->
        {:error, :must_move_last_moved}

      match.extra_turn != no_extra_turn() && match.extra_turn == to_string(old_coord.x) <> to_string(old_coord.y) && old_coord == new_coord ->
        Games.update_match(match, %{turn_id: enemy_id, extra_turn: no_extra_turn()})

      string_at(match.board, new_coord.x, new_coord.y) != empty() ->
        {:error, :must_move_to_empty}

      match.extra_turn != no_extra_turn() && match.extra_turn == to_string(old_coord.x) <> to_string(old_coord.y) ->
        piece = string_at(match.board, old_coord.x, old_coord.y)
        cond do
          piece == white_pawn() ->
            if old_coord.x + 2 == new_coord.x && (old_coord.y - 2 == new_coord.y || old_coord.y + 2 == new_coord.y) &&
                (string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_pawn ||
                string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_king) do
              moved_piece = promote(new_coord, pawn, king)
              make_move_capture(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)
            else
              {:error, :invalid_move}
            end

          piece == black_pawn() ->
            if old_coord.x - 2 == new_coord.x && (old_coord.y - 2 == new_coord.y || old_coord.y + 2 == new_coord.y) &&
                (string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_pawn ||
                string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_king) do
              moved_piece = promote(new_coord, pawn, king)
              make_move_capture(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)
            else
              {:error, :invalid_move}
            end

          piece == white_king() || piece == black_king() ->
            if (old_coord.x - 2 == new_coord.x || old_coord.x + 2 == new_coord.x) && (old_coord.y - 2 == new_coord.y || old_coord.y + 2 == new_coord.y) &&
                (string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_pawn ||
                string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_king) do
              moved_piece = king
              make_move_capture(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)
            else
              {:error, :invalid_move}
            end
        end

      true ->
        piece = string_at(match.board, old_coord.x, old_coord.y)
        case piece do
          ^pawn ->
            cond do
              pawn == white_pawn() ->
                cond do
                  old_coord.x + 1 == new_coord.x && (old_coord.y - 1 == new_coord.y || old_coord.y + 1 == new_coord.y) ->
                    moved_piece = promote(new_coord, pawn, king)
                    make_move(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)

                  old_coord.x + 2 == new_coord.x && (old_coord.y - 2 == new_coord.y || old_coord.y + 2 == new_coord.y) &&
                      (string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_pawn ||
                      string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_king) ->
                    moved_piece = promote(new_coord, pawn, king)
                    make_move_capture(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)

                  true -> {:error, :invalid_move}
                end

              pawn == black_pawn() ->
                cond do
                  old_coord.x - 1 == new_coord.x && (old_coord.y - 1 == new_coord.y || old_coord.y + 1 == new_coord.y) ->
                    moved_piece = promote(new_coord, pawn, king)
                    make_move(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)

                  old_coord.x - 2 == new_coord.x && (old_coord.y - 2 == new_coord.y || old_coord.y + 2 == new_coord.y) &&
                      (string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_pawn ||
                      string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_king) ->
                    moved_piece = promote(new_coord, pawn, king)
                    make_move_capture(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)

                    true -> {:error, :invalid_move}
                end
            end

          ^king ->
            cond do
              (old_coord.x - 1 == new_coord.x || old_coord.x + 1 == new_coord.x) && (old_coord.y - 1 == new_coord.y || old_coord.y + 1 == new_coord.y) ->
                moved_piece = king
                make_move(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)

              (old_coord.x - 2 == new_coord.x || old_coord.x + 2 == new_coord.x) && (old_coord.y - 2 == new_coord.y || old_coord.y + 2 == new_coord.y) &&
                  (string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_pawn ||
                  string_at(match.board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2)) == enemy_king) ->
                moved_piece = king
                make_move_capture(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match)

                true -> {:error, :invalid_move}
            end

          _ ->
            {:error, :not_your_figurine}
        end
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:ok, opts}
  end

  defp white_pawn(), do: "w"

  defp white_king(), do: "W"

  defp black_pawn(), do: "b"

  defp black_king(), do: "B"

  defp empty(), do: "e"

  defp no_extra_turn(), do: "n"

  defp initial_board(), do: "wewewewe,ewewewew,wewewewe,eeeeeeee,eeeeeeee,ebebebeb,bebebebe,ebebebeb"

  defp string_at(string, x, y) do
    String.at(string, 9 * x + y)
  end

  defp string_replace_at(string, x, y, value) do
    String.to_charlist(string)
    |> List.replace_at(9 * x + y, value)
    |> List.to_string()
  end

  # defp get_board_map(board_string) do
  #   split = String.split(board_string, ",")
  #   map_matrix = Enum.reduce split, {0, %{}}, fn x, {row, result} ->
  #     graphem = String.graphemes(x)
  #     map_row = Enum.reduce graphem, {0, %{}}, fn y, {column, acc} ->
  #       {column + 1, Map.put(acc, column, y)}
  #     end
  #     {_, map} = map_row
  #     {row + 1, Map.put(result, row, map)}
  #   end
  #   {_, board_map} = map_matrix
  #   board_map
  # end

  # defp get_board_string(board_map) do
  #   board_string = Enum.reduce board_map, "", fn x, result ->
  #     {_, row} = x
  #     row_string = Enum.reduce row, "", fn y, acc ->
  #       {_, letter} = y
  #       acc <> letter
  #     end
  #     result <> row_string <> ","
  #   end
  #   String.trim_trailing(board_string, ",")
  # end

  defp make_move(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match) do
    # new_board_map = Map.put(board_map, old_coord.x, Map.put(board_map[old_coord.x], old_coord.y, empty()))
    # new_board_map = Map.put(new_board_map, new_coord.x, Map.put(new_board_map[new_coord.x], new_coord.y, moved_piece))
    # board_string = get_board_string(new_board_map)
    board = string_replace_at(match.board, old_coord.x, old_coord.y, empty())
    board = string_replace_at(board, new_coord.x, new_coord.y, moved_piece)
    if enemy_can_move?(board, enemy_pawn, enemy_king, pawn, king) do
      Games.update_match(match, %{turn_id: enemy_id, board: board})
    else
      Games.update_match(match, %{winner_id: my_id, board: board})
    end
  end

  defp promote(new_coord, pawn, king) do
    cond do
      pawn == white_pawn() ->
        if new_coord.x == 7 do
          king
        else
          pawn
        end

      pawn == black_pawn() ->
        if new_coord.x == 0 do
          king
        else
          pawn
        end
    end
  end

  defp make_move_capture(old_coord, new_coord, moved_piece, pawn, king, enemy_pawn, enemy_king, my_id, enemy_id, match) do
    # new_board_map = Map.put(board_map, old_coord.x, Map.put(board_map[old_coord.x], old_coord.y, empty()))
    # new_board_map = Map.put(new_board_map, new_coord.x, Map.put(new_board_map[new_coord.x], new_coord.y, moved_piece))
    # new_board_map = Map.put(new_board_map, (old_coord.x + new_coord.x) / 2, Map.put(new_board_map[(old_coord.x + new_coord.x) / 2], (old_coord.y + new_coord.y) / 2, empty()))
    # board_string = get_board_string(new_board_map)
    board = string_replace_at(match.board, old_coord.x, old_coord.y, empty())
    board = string_replace_at(board, new_coord.x, new_coord.y, moved_piece)
    board = string_replace_at(board, div(old_coord.x + new_coord.x, 2), div(old_coord.y + new_coord.y, 2), empty())
    cond do
      !String.contains?(board, [enemy_pawn, enemy_king]) ->
        Games.update_match(match, %{winner_id: my_id, board: board, extra_turn: no_extra_turn()})

      true ->
        extra_turn = extra_turn(new_coord, moved_piece, enemy_pawn, enemy_king, board)
        if extra_turn == no_extra_turn() do
          if enemy_can_move?(board, enemy_pawn, enemy_king, pawn, king) do
            Games.update_match(match, %{turn_id: enemy_id, board: board, extra_turn: extra_turn})
          else
            Games.update_match(match, %{winner_id: my_id, board: board, extra_turn: extra_turn})
          end
        else
          Games.update_match(match, %{turn_id: my_id, board: board, extra_turn: extra_turn})
        end
    end
  end

  defp extra_turn(new_coord, moved_piece, enemy_pawn, enemy_king, board) do
    cond do
      moved_piece == white_pawn() ->
        cond do
          new_coord.x + 2 < 8 && new_coord.y + 2 < 8 && string_at(board, new_coord.x + 2, new_coord.y + 2) == empty() &&
                (string_at(board, new_coord.x + 1, new_coord.y + 1) == enemy_pawn || string_at(board, new_coord.x + 1, new_coord.y + 1) == enemy_king) ->
              to_string(new_coord.x) <> to_string(new_coord.y)

          new_coord.x + 2 < 8 && new_coord.y - 2 >= 0 && string_at(board, new_coord.x + 2, new_coord.y - 2) == empty() &&
              (string_at(board, new_coord.x + 1, new_coord.y - 1) == enemy_pawn || string_at(board, new_coord.x + 1, new_coord.y - 1) == enemy_king) ->
            to_string(new_coord.x) <> to_string(new_coord.y)

          true -> no_extra_turn()
        end

      moved_piece == black_pawn() ->
        cond do
          new_coord.x - 2 >= 0 && new_coord.y + 2 < 8 && string_at(board, new_coord.x - 2, new_coord.y + 2) == empty() &&
              (string_at(board, new_coord.x - 1, new_coord.y + 1) == enemy_pawn || string_at(board, new_coord.x - 1, new_coord.y + 1) == enemy_king) ->
            to_string(new_coord.x) <> to_string(new_coord.y)

          new_coord.x - 2 >= 0 && new_coord.y - 2 >= 0 && string_at(board, new_coord.x - 2, new_coord.y - 2) == empty() &&
              (string_at(board, new_coord.x - 1, new_coord.y - 1) == enemy_pawn || string_at(board, new_coord.x - 1, new_coord.y - 1) == enemy_king) ->
            to_string(new_coord.x) <> to_string(new_coord.y)

          true -> no_extra_turn()
        end

      moved_piece == white_king() || moved_piece == black_king() ->
        cond do
          new_coord.x + 2 < 8 && new_coord.y + 2 < 8 && string_at(board, new_coord.x + 2, new_coord.y + 2) == empty() &&
              (string_at(board, new_coord.x + 1, new_coord.y + 1) == enemy_pawn || string_at(board, new_coord.x + 1, new_coord.y + 1) == enemy_king) ->
            to_string(new_coord.x) <> to_string(new_coord.y)

          new_coord.x + 2 < 8 && new_coord.y - 2 >= 0 && string_at(board, new_coord.x + 2, new_coord.y - 2) == empty() &&
              (string_at(board, new_coord.x + 1, new_coord.y - 1) == enemy_pawn || string_at(board, new_coord.x + 1, new_coord.y - 1) == enemy_king) ->
            to_string(new_coord.x) <> to_string(new_coord.y)

          new_coord.x - 2 >= 0 && new_coord.y + 2 < 8 && string_at(board, new_coord.x - 2, new_coord.y + 2) == empty() &&
              (string_at(board, new_coord.x - 1, new_coord.y + 1) == enemy_pawn || string_at(board, new_coord.x - 1, new_coord.y + 1) == enemy_king) ->
            to_string(new_coord.x) <> to_string(new_coord.y)

          new_coord.x - 2 >= 0 && new_coord.y - 2 >= 0 && string_at(board, new_coord.x - 2, new_coord.y - 2) == empty() &&
              (string_at(board, new_coord.x - 1, new_coord.y - 1) == enemy_pawn || string_at(board, new_coord.x - 1, new_coord.y - 1) == enemy_king) ->
            to_string(new_coord.x) <> to_string(new_coord.y)

          true -> no_extra_turn()
        end
    end
  end

  defp enemy_can_move?(board, enemy_pawn, enemy_king, pawn, king) do
    can_move?(false, board, 0, enemy_pawn, enemy_king, pawn, king)
  end

  defp can_move?(true, _, _, _, _, _, _) do
    true
  end

  defp can_move?(false, board, n, enemy_pawn, enemy_king, pawn, king) do
    cond do
      n >= String.length(board) ->
        false

      String.at(board, n) == enemy_pawn || String.at(board, n) == enemy_king ->
        piece = String.at(board, n)
        i = div(n, 9)
        j = rem(n, 9)
        cond do
          piece == white_pawn() ->
            if (i + 1 < 8 && j - 1 >= 0 && string_at(board, i + 1, j - 1) == empty()) || (i + 1 < 8 && j + 1 < 8 && string_at(board, i + 1, j + 1) == empty()) ||
                (i + 2 < 8 && j - 2 >= 0 && string_at(board, i + 2, j - 2) == empty() && (string_at(board, i + 1, j - 1) == black_pawn() || string_at(board, i + 1, j - 1) == black_king())) ||
                (i + 2 < 8 && j + 2 < 8 && string_at(board, i + 2, j + 2) == empty() && (string_at(board, i + 1, j + 1) == black_pawn() || string_at(board, i + 1, j + 1) == black_king())) do
              can_move?(true, board, n + 1, enemy_pawn, enemy_king, pawn, king)
            else
              can_move?(false, board, n + 1, enemy_pawn, enemy_king, pawn, king)
            end

          piece == black_pawn() ->
            if (i - 1 >= 0 && j - 1 >= 0 && string_at(board, i - 1, j - 1) == empty()) || (i - 1 >= 0 && j + 1 < 8 && string_at(board, i - 1, j + 1) == empty()) ||
                (i - 2 >= 0 && j - 2 >= 0 && string_at(board, i - 2, j - 2) == empty() && (string_at(board, i - 1, j - 1) == white_pawn() || string_at(board, i - 1, j - 1) == white_king())) ||
                (i - 2 >= 0 && j + 2 < 8 && string_at(board, i - 2, j + 2) == empty() && (string_at(board, i - 1, j + 1) == white_pawn() || string_at(board, i - 1, j + 1) == white_king())) do
              can_move?(true, board, n + 1, enemy_pawn, enemy_king, pawn, king)
            else
              can_move?(false, board, n + 1, enemy_pawn, enemy_king, pawn, king)
            end

          true ->
            if (i - 1 >= 0 && j - 1 >= 0 && string_at(board, i - 1, j - 1) == empty()) || (i - 1 >= 0 && j + 1 < 8 && string_at(board, i - 1, j + 1) == empty()) ||
                (i + 1 < 8 && j - 1 >= 0 && string_at(board, i + 1, j - 1) == empty()) || (i + 1 < 8 && j + 1 < 8 && string_at(board, i + 1, j + 1) == empty()) ||
                (i - 2 >= 0 && j - 2 >= 0 && string_at(board, i - 2, j - 2) == empty() && (string_at(board, i - 1, j - 1) == pawn || string_at(board, i - 1, j - 1) == king)) ||
                (i - 2 >= 0 && j + 2 < 8 && string_at(board, i - 2, j + 2) == empty() && (string_at(board, i - 1, j + 1) == pawn || string_at(board, i - 1, j + 1) == king)) ||
                (i + 2 < 8 && j - 2 >= 0 && string_at(board, i + 2, j - 2) == empty() && (string_at(board, i + 1, j - 1) == pawn || string_at(board, i + 1, j - 1) == king)) ||
                (i + 2 < 8 && j + 2 < 8 && string_at(board, i + 2, j + 2) == empty() && (string_at(board, i + 1, j + 1) == pawn || string_at(board, i + 1, j + 1) == king)) do
              can_move?(true, board, n + 1, enemy_pawn, enemy_king, pawn, king)
            else
              can_move?(false, board, n + 1, enemy_pawn, enemy_king, pawn, king)
            end
        end

      true ->
        can_move?(false, board, n + 1, enemy_pawn, enemy_king, pawn, king)
    end
  end
end
