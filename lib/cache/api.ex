defmodule Kyasshu.Cache do
  alias Kyasshu.Cache.Connection

  @prefix_exec "KYASSHU:EXEC"

  def get_exec(hash) do
    case Redix.command(Connection, ["GET", "#{@prefix_exec}:#{hash}"]) do
      {:error, err} ->
        {:error, err}

      {:ok, res} ->
        case res do
          nil -> {:ok, nil}
          _ -> {:ok, Jason.decode!(res)}
        end
    end
  end

  def get_exec!(hash) do
    case get_exec(hash) do
      {:error, err} -> raise err
      {:ok, res} -> res
    end
  end

  def set_exec(hash, payload, expire \\ 604_800_000) do
    Redix.command(
      Connection,
      ["SET", "#{@prefix_exec}:#{hash}", Jason.encode!(payload), "EX", expire]
    )
  end

  def set_exec!(hash, payload, expire \\ 604_800_000) do
    case set_exec(hash, payload, expire) do
      {:error, err} -> raise err
      {:ok, res} -> res
    end
  end
end
