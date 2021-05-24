import Config

Dotenvy.source!(".env")

bind_split = System.get_env("BIND_ADDRESS", "0.0.0.0:8080") |> String.split(":")
bind_split = if length(bind_split) == 1, do: bind_split ++ ["8080"], else: bind_split

config :kyasshu,
  debug: System.get_env("DEBUG", "") |> String.downcase() == "true"

config :kyasshu, Webserver,
  ip:
    bind_split
    |> Enum.at(0)
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple(),
  port: bind_split |> Enum.at(1) |> String.to_integer()

config :kyasshu, Ranna,
  endpoint: System.get_env("RANNA_ENDPOINT"),
  auth_token: System.get_env("RANNA_AUTHTOKEN", "")
