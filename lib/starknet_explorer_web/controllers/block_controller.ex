defmodule StarknetExplorerWeb.BlockController do

  use StarknetExplorerWeb, :controller

  alias StarknetExplorer.Rpc

  def index(conn, _params) do
    case Rpc.get_latest_block() do
      {:ok, latest_block} ->
        render(conn, "index.html", latest_block: latest_block)

      {:error, error} ->
        render(conn, "index.html", error: error)
    end

  end

end
