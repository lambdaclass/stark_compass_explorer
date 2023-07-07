defmodule StarknetExplorer.Rpc do
  use Tesla

  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  def get_latest_block(), do: send_request("starknet_getBlockWithTxs", ["latest"])
  def get_last_n_events(n), do: send_request("starknet_getEvents", [%{"chunk_size" => n}])

  def get_block_height(),
    do: send_request("starknet_blockNumber", [])

  def get_block_by_number(number) when is_integer(number),
    do: send_request("starknet_getBlockWithTxs", [%{block_number: number}])

  def get_block_by_hash(number) when is_binary(number),
    do: send_request("starknet_getBlockWithTxs", [%{block_hash: number}])

  def get_transaction(transaction_hash),
    do: send_request("starknet_getTransactionByHash", [transaction_hash])

  def get_transaction_receipt(transaction_hash),
    do: send_request("starknet_getTransactionReceipt", [transaction_hash])

  def get_state_update(),
    do: send_request("starknet_getStateUpdate", ["latest"])

  # We can check deployed contracts on a given block with this method.
  def get_state_update(block_number) when is_number(block_number),
    do: send_request("starknet_getStateUpdate", [%{block_number: block_number}])

  def get_state_update(block_hash) when is_binary(block_hash),
    do: send_request("starknet_getStateUpdate", [%{block_hash: block_hash}])

  # We can parse abis with this method.
  def get_class(block_number, class_hash),
    do: send_request("starknet_getClass", [%{block_number: block_number}, class_hash])

  def get_class_at(block_number, contract_address),
    do: send_request("starknet_getClassAt", [%{block_number: block_number}, contract_address])

  defp send_request(method, args) do
    payload = build_payload(method, args)

    host = Application.fetch_env!(:starknet_explorer, :rpc_host)

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
