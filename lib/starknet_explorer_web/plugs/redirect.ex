defmodule StarknetExplorerWeb.Plug.Redirect do
  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    conn
    # |> Phoenix.Controller.redirect(to: "/mainnet")
    # |> Plug.Conn.halt()
  end
end
