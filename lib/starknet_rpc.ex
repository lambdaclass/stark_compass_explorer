defmodule StarknetExplorer.Rpc do
  use Tesla

  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  def get_latest_block(), do: send_request("starknet_getBlockWithTxs", ["latest"])

  defp send_request(method, args) do
    payload = build_payload(method, args)

    host =
      "https://starknet-mainnet.infura.io/v3/" <>
        Application.fetch_env!(:starknet_explorer, :api_key)

    {:ok, rsp} = post(host, payload)

    handle_response(rsp)
  end

  defp build_payload(method, params) do
    %{
      jsonrpc: "2.0",
      id: Enum.random(1..9_999_999),
      method: method,
      params: params
    }
    |> Jason.encode!()
  end

  defp handle_response(rsp) do
    case Jason.decode!(rsp.body) do
      %{"result" => result} ->
        {:ok, result}

      %{"error" => error} ->
        {:error, error}
    end
  end
end
