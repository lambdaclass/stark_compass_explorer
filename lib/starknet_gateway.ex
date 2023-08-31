defmodule StarknetExplorer.Gateway do
  use Tesla
  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  @gateway_url "https://alpha-mainnet.starknet.io/feeder_gateway"

  def block_gas_fee_in_wei(block_hash = <<"0x", _hash::binary>>),
    do: gas_fee_request(blockHash: block_hash)

  def block_gas_fee_in_wei(block_number) when is_integer(block_number),
    do: gas_fee_request(blockNumber: block_number)

  defp gas_fee_request(query) do
    case gateway_request("get_block", query) do
      {:ok, map} ->
        gas_price = Map.get(map, "gas_price")
        {:ok, gas_price}

      err ->
        err
    end
  end

  defp gateway_request(method, query) do
    method
    |> form_url
    |> get(query: query)
    |> handle_response()
  end

  defp form_url(method), do: @gateway_url <> "/" <> method
  defp handle_response({:ok, rsp = %Tesla.Env{}}), do: Jason.decode(rsp.body)
  defp handle_response(err), do: err
end
