defmodule StarknetExplorer.Rpc do
  use Tesla
  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  def get_latest_block_no_cache(network),
    do: send_request_no_cache("starknet_getBlockWithTxs", ["latest"], network)

  def get_latest_block(network),
    do: send_request("starknet_getBlockWithTxs", ["latest"], network)

  def get_last_n_events(n, network),
    do: send_request("starknet_getEvents", [%{"chunk_size" => n}], network)

  def get_block_events_paginated(block_hash, pagination, network),
    do:
      send_request(
        "starknet_getEvents",
        [
          Map.merge(
            %{from_block: %{block_hash: block_hash}, to_block: %{block_hash: block_hash}},
            pagination
          )
        ],
        network
      )

  def get_events(params, network),
    do:
      send_request(
        "starknet_getEvents",
        [
          params
        ],
        network
      )

  def get_block_height_no_cache(network),
    do: send_request_no_cache("starknet_blockNumber", [], network)

  def get_block_height(network),
    do: send_request("starknet_blockNumber", [], network)

  def get_block_by_number(number, network) when is_integer(number),
    do: send_request("starknet_getBlockWithTxs", [%{block_number: number}], network)

  def get_block_by_hash(number, network) when is_binary(number),
    do: send_request("starknet_getBlockWithTxs", [%{block_hash: number}], network)

  def get_transaction(transaction_hash, network),
    do: send_request("starknet_getTransactionByHash", [transaction_hash], network)

  def get_transaction_receipt(transaction_hash, network),
    do: send_request("starknet_getTransactionReceipt", [transaction_hash], network)

  def get_class_at(block_id, contract_address, network),
    do: send_request("starknet_getClassAt", [block_id, contract_address], network)

  def get_class(block_id, class_hash, network),
    do: send_request("starknet_getClass", [block_id, class_hash], network)

  def get_state_update(block_id, network),
    do: send_request("starknet_getStateUpdate", [block_id], network)

  def call(block_id, contract_address, selector, network),
    do:
      send_request(
        "starknet_call",
        [
          %{contract_address: contract_address, entry_point_selector: selector, calldata: []},
          block_id
        ],
        network
      )

  defp send_request(method, args, network) when network in [:mainnet, :testnet, :testnet2] do
    payload = build_payload(method, args)

    case cache_lookup(method, args, network) do
      :cache_miss ->
        host = fetch_rpc_host(network)
        {:ok, rsp} = post(host, payload)
        response = handle_response(rsp)
        # Cache miss, so save this result.
        case handle_response(rsp) do
          {:ok, result} ->
            Cachex.put(:"#{network}_request_cache", {method, args}, result)

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
    host = fetch_rpc_host(network)
    {:ok, rsp} = post(host, payload)
    handle_response(rsp)
  end

  defp fetch_rpc_host(:mainnet), do: Application.fetch_env!(:starknet_explorer, :rpc_host)
  defp fetch_rpc_host(:testnet), do: Application.fetch_env!(:starknet_explorer, :testnet_host)
  defp fetch_rpc_host(:testnet2), do: Application.fetch_env!(:starknet_explorer, :testnet_2_host)

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

  defp cache_lookup("starknet_getBlockWithTxs", [%{block_number: number}], network),
    do: do_cache_lookup(:block_cache, number, network)

  defp cache_lookup("starknet_getBlockWithTxs", [%{block_hash: hash}], network),
    do: do_cache_lookup(:block_cache, hash, network)

  defp cache_lookup("starknet_getTransactionByHash", [transaction_hash], network),
    do: do_cache_lookup(:tx_cache, transaction_hash, network)

  defp cache_lookup(method, args, network),
    do: do_cache_lookup(:request_cache, {method, args}, network)

  defp do_cache_lookup(cache_type, key, network)
       when cache_type in [:block_cache, :tx_cache, :request_cache] and
              network in [:mainnet, :testnet, :testnet2] do
    cache_name = :"#{network}_#{cache_type}"

    case Cachex.get(cache_name, key) do
      {:ok, value} when not is_nil(value) ->
        {:ok, value}

      _ ->
        :cache_miss
    end
  end
end
