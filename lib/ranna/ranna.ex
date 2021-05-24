defmodule Kyasshu.Ranna do
  def exec(payload) do
    Task.Supervisor.async(
      Kyasshu.Ranna.Supervisor,
      fn -> do_request(payload) end
    )
    |> Task.await(60_000)
  end

  defp client do
    endpoint = Application.get_env(:kyasshu, Ranna)[:endpoint]
    token = Application.get_env(:kyasshu, Ranna)[:auth_token]

    if endpoint == nil do
      raise "RANNA_ENDPOINT must be defined"
    end

    middleware = [
      {Tesla.Middleware.BaseUrl, endpoint},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [{"authorization", "basic " <> token}, {"content-type", "application/json"}]}
    ]

    Tesla.client(middleware)
  end

  defp do_request(payload) do
    res = Tesla.post(client(), "/v1/exec", Jason.encode!(payload))

    case res do
      {:error, e} ->
        {:error, e}

      {:ok, res} ->
        if res.status >= 400 do
          {:error, res.body}
        else
          {:ok, res.body}
        end
    end
  end
end
