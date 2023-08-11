defmodule StarknetExplorerWeb.Plug.Redirect do
  def init(opts) do
    opts
  end

  def call(conn = %{request_path: path}, _opts) do
    case path do
      # Redirect a "mainnet" leading route
      # to a route leaded by a slash
      <<"/mainnet", path::binary>> ->
        conn
        |> Phoenix.Controller.redirect(to: path)
        |> Plug.Conn.halt()

      # Redirect to root if route is unknown
      _ ->
        conn
        |> Phoenix.Controller.redirect(to: "/")
        |> Plug.Conn.halt()
    end
  end
end
