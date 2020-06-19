defmodule CheckersWeb.SessionController do
  use CheckersWeb, :controller

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"username" => username, "password" => password}}) do
    case Checkers.Accounts.authenticate_by_username_and_password(username, password) do
      {:ok, user} ->
        conn
        |> CheckersWeb.Auth.login(user)
        |> put_flash(:info, "You have logged in!")
        # |> redirect(to: Routes.page_path(conn, :index))
        |> redirect(to: Routes.lobby_path(conn, :show))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid login input")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> CheckersWeb.Auth.logout()
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
