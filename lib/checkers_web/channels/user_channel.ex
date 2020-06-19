defmodule CheckersWeb.UserChannel do
  use CheckersWeb, :channel

  def join("user:" <> user_id, _params, socket) do
    {:ok, assign(socket, :user_id, String.to_integer(user_id))}
  end
  #mrvicu kasnije kad radim invite
  alias Checkers.Accounts

  def handle_in("invite", params, socket) do
    # later check if params["destId"] je slobodan za igru
    # na frontu rejectam ak je zauzet
    user = Accounts.get_user!(params["sourceId"])
    broadcast!(socket, "invite", %{
      user: %{username: user.username},
      source_id: params["sourceId"],
      dest_id: params["destId"]
    })
    {:reply, :ok, socket}
  end

  alias Checkers.GameServer

  def handle_in("accept", params, socket) do
    result = GameServer.create_match(params["destId"], params["sourceId"])
    case result do
      {:ok, match} ->
        broadcast!(socket, "accept", %{
        source_id: params["sourceId"],
        dest_id: params["destId"],
        match_id: match.id
        })
        {:reply, :ok, socket}
      _ ->
        {:noreply, socket}
    end
  end

  def handle_in("reject", params, socket) do
    broadcast!(socket, "reject", %{
      source_id: params["sourceId"],
      dest_id: params["destId"]
    })
    {:reply, :ok, socket}
  end

  def handle_in("cancel", params, socket) do
    broadcast!(socket, "cancel", %{
      source_id: params["sourceId"],
      dest_id: params["destId"]
    })
    {:reply, :ok, socket}
  end
end
