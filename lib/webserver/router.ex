defmodule Kyasshu.Webserver.Router do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger
  import Kyasshu.Webserver.Util

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  if Application.get_env(:kyasshu, :debug) do
    Logger.warn("debug mode engaged")
    plug(CORSPlug)
  end

  plug(:match)
  plug(:dispatch)

  post "/exec" do
    body = conn.body_params

    payload = %{
      arguments: body["arguments"],
      code: body["code"],
      environment: body["environment"],
      language: body["language"]
    }

    Kyasshu.Ranna.exec(payload) |> IO.inspect()

    "ok" |> resp_json(conn)
  end

  get "/test" do
    "ok" |> resp_json(conn)
  end

  match _ do
    if conn.method == "OPTIONS" do
      conn |> resp_json_ok()
    else
      conn |> resp_json_not_found()
    end
  end
end
