defmodule CheckersWeb.LobbyController do
  use CheckersWeb, :controller
  plug :authenticate_user when action in [:show]

  alias Checkers.Games
  def show(conn, _) do
    user_id = get_session(conn, :user_id) #dodan userid
    current_matches = Games.current_matches(user_id)
    render(conn, "show.html", user_id: user_id, current_matches: current_matches)
    # render(conn, "show.html", user_id: user_id) #dodan userid
  end
end
