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

    payload_hash = payload |> Kyasshu.Hashing.get_hash()

    res =
      case Kyasshu.Cache.get_exec(payload_hash) do
        {:ok, nil} ->
          case Kyasshu.Ranna.exec(payload) do
            {:error, err} ->
              {:error, err}

            {:ok, body, status} ->
              data = %{
                body: body |> Map.put(:cache_date, DateTime.utc_now()),
                status: status
              }

              Kyasshu.Cache.set_exec!(
                payload_hash,
                data,
                Application.get_env(:kyasshu, Redis)[:duration]
              )

              {:ok, data, false}
          end

        {:ok, res} ->
          {:ok, %{body: res["body"], status: res["status"]}, true}

        {:error, err} ->
          {:error, err}
      end

    case res do
      {:ok, %{body: body, status: status}, cached} ->
        body |> Map.put("from_cache", cached) |> resp_json(conn, status)

      {:error, err} ->
        err |> resp_json(conn, 500)
    end
  end

  match _ do
    if conn.method == "OPTIONS" do
      conn |> resp_json_ok()
    else
      conn |> resp_json_not_found()
    end
  end
end
