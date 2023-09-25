defmodule StarknetExplorer.Gateway do
  use Tesla
  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  @gateway_url "starknet.io/feeder_gateway"
  @mainnet_gateway_url "https://alpha-mainnet." <> @gateway_url
  @testnet_gateway_url "https://alpha4." <> @gateway_url
  @testnet2_gateway_url "https://alpha4-2." <> @gateway_url

  def fetch_block(block_hash, network \\ :mainnet)

  def fetch_block(block_hash = <<"0x", _hash::binary>>, network),
    do: get_block_request(%{blockHash: block_hash}, network)

  def fetch_block(block_number, network) when is_integer(block_number),
    do: get_block_request(%{blockNumber: block_number}, network)

  def trace_transaction(transaction_hash, network),
    do: gateway_request("get_transaction_trace", %{transactionHash: transaction_hash}, network)

  defp get_block_request(query, network), do: gateway_request("get_block", query, network)

  defp gateway_request(method, query, network) do
    method
    |> form_url(network)
    |> get(query: query)
    |> handle_response()
  end

  defp form_url(method, :testnet), do: @testnet_gateway_url <> "/" <> method
  defp form_url(method, :testnet2), do: @testnet2_gateway_url <> "/" <> method
  defp form_url(method, :mainnet), do: @mainnet_gateway_url <> "/" <> method

  defp handle_response({:ok, rsp = %Tesla.Env{}}), do: Jason.decode(rsp.body)
  defp handle_response(err), do: err
end
