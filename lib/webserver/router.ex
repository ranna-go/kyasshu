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

  post "/v1/exec" do
    body = conn.body_params

    conn |> fetch_query_params()
    bypass_cache = conn |> query_true?("bypass_cache")

    payload = %{
      arguments: body["arguments"],
      code: body["code"],
      environment: body["environment"],
      language: body["language"],
      inline_expression: body["inline_expression"],
    }

    payload_hash = payload |> Kyasshu.Hashing.get_hash()

    from_cache =
      if bypass_cache do
        {:ok, nil}
      else
        Kyasshu.Cache.get_exec(payload_hash)
      end

    res =
      case from_cache do
        {:ok, nil} ->
          case Kyasshu.Ranna.exec(payload) do
            {:error, err} ->
              {:error, err}

            {:ok, body, status} when is_map(body) ->
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

            {:ok, body, status} when is_binary(body) ->
              {:ok, body, status}
          end

        {:ok, res} ->
          {:ok, %{body: res["body"], status: res["status"]}, true}

        {:error, err} ->
          {:error, err}
      end

    case res do
      {:ok, %{body: body, status: status}, cached} ->
        body |> Map.put("from_cache", cached) |> resp_json(conn, status)

      {:ok, data, status} ->
        data |> resp_json(conn, status)

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
