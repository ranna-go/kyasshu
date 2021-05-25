defmodule Kyasshu.Hashing do
  def get_hash(payload) do
    :crypto.hash(:md5, Jason.encode!(payload))
    |> Base.encode16(case: :lower)
  end
end
