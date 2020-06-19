defmodule CheckersWeb.MatchController do
  use CheckersWeb, :controller
  plug :authenticate_user when action in [:show]

  alias Checkers.Games

  def show(conn, %{"id" => id}) do
    user_id = get_session(conn, :user_id) #dodan userid
    match = Games.get_match!(id)
    if match.winner_id == nil && match.turn_id != nil do
      render(conn, "show.html", match: match, user_id: user_id) #dodan userid
    else
      redirect(conn, to: "/lobby")
    end
  end
end
