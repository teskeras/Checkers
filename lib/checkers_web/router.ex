defmodule CheckersWeb.Router do
  use CheckersWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CheckersWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CheckersWeb do
    pipe_through :browser

    get "/", PageController, :index
    # get "user", UserController, :new i show za id
    resources "/user", UserController, only: [:show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    get "/lobby", LobbyController, :show
    get "/match/:id", MatchController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", CheckersWeb do
  #   pipe_through :api
  # end
end
