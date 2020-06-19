defmodule CheckersWeb.UserController do
  use CheckersWeb, :controller

  alias Checkers.Accounts
  alias Checkers.Accounts.User
  alias Checkers.Games
  plug :authenticate_user when action in [:show]

  def new(conn, _params) do
    # changeset = Accounts.change_user(%User{})
    changeset = Accounts.change_registration(%User{}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user(id)
    last_matches = Games.last_matches(id)
    render(conn, "show.html", user: user, last_matches: last_matches)
    # case authenticate(conn) do
    #   %Plug.Conn{halted: true} = conn ->
    #     conn

    #   conn ->
    #     user = Accounts.get_user(id)
    #     render(conn, "show.html", user: user)
    # end
  end

  def create(conn, %{"user" => user_params}) do
    # {:ok, user} = Accounts.create_user(user_params)
    # conn
    #     |> put_flash(:info, "#{user.name} created!")
    #     |> redirect(to: Routes.page_path(conn, :index))

    # poslije još komentar
    #case Accounts.create_user(user_params) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> CheckersWeb.Auth.login(user) #dodat tek nakon logina
        |> put_flash(:info, "#{user.name} created!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  # defp authenticate(conn) do
  # defp authenticate(conn, _opts) do
  #   if conn.assigns.current_user do
  #     conn
  #   else
  #     conn
  #     |> put_flash(:error, "You must be logged in to access that page")
  #     |> redirect(to: Routes.page_path(conn, :index))
  #     |> halt()
  #   end
  # end
end
