defmodule CheckersWeb.LobbyView do
  use CheckersWeb, :view

  alias Checkers.Accounts

  def get_details(current_matches) do
    Enum.reduce(current_matches, [], fn x, acc ->
      white = Accounts.get_user!(x.white_id)
      black = Accounts.get_user!(x.black_id)
      acc ++ [{x.id, white.username, black.username}]
      # {key + 1, Map.put(acc, key, {x.id, x.white_id, x.black_id})}
    end)

  end
end
