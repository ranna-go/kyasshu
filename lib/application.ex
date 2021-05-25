defmodule Kyasshu.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {
        Plug.Cowboy,
        plug: Kyasshu.Webserver.Router,
        scheme: :http,
        options: [
          ip: Application.get_env(:kyasshu, Webserver)[:ip],
          port: Application.get_env(:kyasshu, Webserver)[:port]
        ]
      },
      {
        Task.Supervisor,
        name: Kyasshu.Ranna.Supervisor
      },
      Kyasshu.Cache.Supervisor
    ]

    Logger.info("Webserver running ...")

    opts = [strategy: :one_for_one, name: Kyasshu.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
