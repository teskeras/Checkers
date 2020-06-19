defmodule Checkers.Accounts do
  @moduledoc """
  The Accounts context
  """

  alias Checkers.Repo
  alias Checkers.Accounts.User

  # def list_users do
  #   [
  #     %User{id: "1", name: "Stjepan Hardcoded", username: "stjepanhardcoded"}
  #   ]
  # end

  def get_user(id) do
    # Enum.find(list_users(), fn map -> map.id == id end)
    Repo.get(User, id)
  end

  def get_user!(id) do
    Repo.get!(User, id)
  end

  #prestane se koristit kad dodam reg
  # def change_user(%User{} = user) do
  #   User.changeset(user, %{})
  # end

  #prestane se koristit kad dodam reg
  # def create_user(attrs \\ %{}) do
  #   %User{}
  #   |> User.changeset(attrs)
  #   |> Repo.insert()
  # end

  def change_registration(%User{} = user, params) do
    User.registration_changeset(user, params)
  end

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by(params) do
    Repo.get_by(User, params)
  end

  def authenticate_by_username_and_password(username, given_pass) do
    user = get_user_by(username: username)

    cond do
      user && Pbkdf2.verify_pass(given_pass, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :unauthorized}

      true ->
        Pbkdf2.no_user_verify()
        {:error, :not_found}
    end
  end

  #presence
  import Ecto.Query

  def list_users_with_ids(ids) do
    Repo.all(from(u in User, where: u.id in ^ids))
  end
end
