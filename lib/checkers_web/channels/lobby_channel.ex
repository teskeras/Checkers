defmodule CheckersWeb.LobbyChannel do
  use CheckersWeb, :channel

  def join("lobby", _params, socket) do
    send(self(), :after_join) #kasnije za presence
    {:ok, socket}
  end

  #kasnije handle in
  alias Checkers.Accounts

  def handle_in(event, params, socket) do
    user = Accounts.get_user!(socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  def handle_in("new_message", params, user, socket) do #dodan user u parametar
    broadcast!(socket, "new_message", %{
      user: %{username: user.username}, #sad imam usera
      body: params["body"]
    })

    {:reply, :ok, socket}
  end

  #kasnije za presence
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", CheckersWeb.Presence.list(socket))
    {:ok, _} = CheckersWeb.Presence.track(socket, socket.assigns.user_id, %{device: "browser"})
    {:noreply, socket}
  end
end
