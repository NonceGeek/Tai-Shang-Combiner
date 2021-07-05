defmodule TaiShangWeb.Router do
  use TaiShangWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {TaiShangWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", TaiShangWeb do
    pipe_through(:browser)

    live("/", GeneratorLive, :index)
    live("/live/parser", ParserLive, :index)
    live("/live/parser_0x03", ParserThreeLive, :index)
    live("/live/setting", ContractSettingLive, :index)
    live("/live/combiner", CombinerLive, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", TaiShangWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: TaiShangWeb.Telemetry)
    end
  end
end
