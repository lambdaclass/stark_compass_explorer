defmodule StarknetExplorer.Gateway do
  use Tesla
  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  @gateway_url "https://alpha-mainnet.starknet.io/feeder_gateway"

  def fetch_block(block_hash = <<"0x", _hash::binary>>),
    do: get_block_request(blockHash: block_hash)

  def fetch_block(block_number) when is_integer(block_number),
    do: get_block_request(blockNumber: block_number)

  defp get_block_request(query), do: gateway_request("get_block", query)

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
