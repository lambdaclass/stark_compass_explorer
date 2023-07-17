defmodule StarknetExplorer.Rpc do
  use Tesla
  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  def get_latest_block_no_cache(network \\ :mainnet),
    do: send_request_no_cache("starknet_getBlockWithTxs", ["latest"], network)

  def get_latest_block(network \\ :mainnet),
    do: send_request("starknet_getBlockWithTxs", ["latest"], network)

  def get_last_n_events(n, network \\ :mainnet),
    do: send_request("starknet_getEvents", [%{"chunk_size" => n}], network)

  def get_block_height(network \\ :mainnet),
    do: send_request("starknet_blockNumber", [], network)

  def get_block_by_number(number, network \\ :mainnet) when is_integer(number),
    do: send_request("starknet_getBlockWithTxs", [%{block_number: number}], network)

  def get_block_by_hash(number, network \\ :mainnet) when is_binary(number),
    do: send_request("starknet_getBlockWithTxs", [%{block_hash: number}], network)

  def get_transaction(transaction_hash, network \\ :mainnet),
    do: send_request("starknet_getTransactionByHash", [transaction_hash], network)

  def get_transaction_receipt(transaction_hash, network \\ :mainnet),
    do: send_request("starknet_getTransactionReceipt", [transaction_hash], network)

  defp send_request(method, args, network) when network in [:mainnet, :testnet, :testnet2] do
    payload = build_payload(method, args)

    case cache_lookup(method, args) do
      :cache_miss ->
        host = Application.fetch_env!(:starknet_explorer, :rpc_host)
        {:ok, rsp} = post(host, payload)
        response = handle_response(rsp)

        # Cache miss, so save this result.
        case handle_response(rsp) do
          {:ok, result} ->
            Cachex.put(:request_cache, {method, args}, result)

          _ ->
            nil
        end

        response

      # Cache hit, so use that value
      {:ok, cached_value} ->
        {:ok, cached_value}
    end
  end

  defp send_request_no_cache(method, args, network)
       when network in [:mainnet, :testnet, :testnet2] do
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

       defp cache_lookup("starknet_getBlockWithTxs", [%{block_number: number}]),
    do: do_cache_lookup(:block_cache, number)

  defp cache_lookup("starknet_getBlockWithTxs", [%{block_hash: hash}]),
    do: do_cache_lookup(:block_cache, hash)

  defp cache_lookup("starknet_getTransactionByHash", [transaction_hash]),
    do: do_cache_lookup(:tx_cache, transaction_hash)

  defp cache_lookup(method, args), do: do_cache_lookup(:request_cache, {method, args})

  defp do_cache_lookup(cache_name, key) when is_atom(cache_name) do
    case Cachex.get(cache_name, key) do
      {:ok, nil} ->
        :cache_miss

      {:ok, value} ->
        {:ok, value}

      _ ->
        :cache_miss
    end
  end
end
