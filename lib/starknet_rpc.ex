defmodule StarknetExplorer.Rpc do
  use Tesla
  require Logger
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

  defp cache_lookup("starknet_getBlockWithTxs", [%{block_number: number}]) do
    case Cachex.get(:block_cache, number) do
      {:ok, nil} ->
        :cache_miss

      {:ok, value} ->
        {:ok, value}

      {:error, _} ->
        :cache_miss
    end
  end

  defp cache_lookup(_, _), do: :cache_miss

  defp send_request(method, args) do
    payload = build_payload(method, args)

    case cache_lookup(method, args) do
      :cache_miss ->
        host = Application.fetch_env!(:starknet_explorer, :rpc_host)

        Logger.info("Cache miss!")

        {:ok, rsp} = post(host, payload)

        handle_response(rsp)

      {:ok, cached_value}->
        Logger.info("Cache hit!")
        {:ok, cached_value}
    end
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
