defmodule StarknetExplorer.Rpc do
  use Tesla

  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  def get_latest_block(), do: send_request("starknet_getBlockWithTxs", ["latest"])

  def get_block_by_number(number) when is_integer(number),
    do: send_request("starknet_getBlockWithTxs", [%{block_number: number}])

  def get_block_by_hash(number) when is_binary(number),
    do: send_request("starknet_getBlockWithTxs", [%{block_hash: number}])

  def get_transaction(transaction_hash), do: send_request("starknet_getTransactionByHash", [transaction_hash])

  def get_transaction_receipt(transaction_hash), do: send_request("starknet_getTransactionReceipt", [transaction_hash])

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
