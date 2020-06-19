defmodule CheckersWeb.MatchChannel do
  use CheckersWeb, :channel

  def join("match:" <> match_id, _params, socket) do
    {:ok, assign(socket, :match_id, String.to_integer(match_id))}
  end

  alias Checkers.Accounts

  def handle_in(event, params, socket) do
    user = Accounts.get_user!(socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  alias Checkers.GameServer

  def handle_in("surrender", params, user, socket) do
    result = GameServer.surrender(params["matchId"], user.id)
    case result do
      {:ok, match} ->
        broadcast!(socket, "move", %{
          board_string: match.board,
          turn_id: match.turn_id,
          extra_turn: match.extra_turn,
          winner_id: match.winner_id,
          white_id: match.white_id,
          black_id: match.black_id
        })
        {:reply, :ok, socket}

      _->
        {:noreply, socket}
    end
  end

  def handle_in("move", params, user, socket) do
    old_coord = %{:x => params["oldCoord"]["x"], :y => params["oldCoord"]["y"]}
    new_coord = %{:x => params["newCoord"]["x"], :y => params["newCoord"]["y"]}
    result = GameServer.move(params["matchId"], user.id, old_coord, new_coord)
    case result do
      {:ok, match} ->
        broadcast!(socket, "move", %{
          board_string: match.board,
          turn_id: match.turn_id,
          extra_turn: match.extra_turn,
          winner_id: match.winner_id,
          white_id: match.white_id,
          black_id: match.black_id
        })
        {:reply, :ok, socket}

      _ ->
        {:noreply, socket}
      end
  end
end
