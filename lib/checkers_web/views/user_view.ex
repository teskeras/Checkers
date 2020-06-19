defmodule CheckersWeb.UserView do
  use CheckersWeb, :view

  alias Checkers.Accounts

  def get_details(last_matches) do
    Enum.reduce last_matches, [], fn x, acc ->
      white = Accounts.get_user!(x.white_id)
      black = Accounts.get_user!(x.black_id)
      winner =
        if x.winner_id == x.white_id do
          white
        else
          black
        end
      acc ++ [{white.username, black.username, winner.username, x.white_id, x.black_id, x.winner_id}]
    end
  end
end
