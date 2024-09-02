defmodule StarknetExplorer.Token do
  defstruct [:address, :name, :symbol]
  alias StarknetExplorer.Rpc

  @whitelisted_tokens_mainnet %{
    "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7" => %{
      address: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
      name: "StarkGate: ETH",
      symbol: "ETH"
    },
    "0x00da114221cb83fa859dbdb4c44beeaa0bb37c7537ad5ae66fe5e0efd20e6eb3" => %{
      address: "0x00da114221cb83fa859dbdb4c44beeaa0bb37c7537ad5ae66fe5e0efd20e6eb3",
      name: "StarkGate: DAI",
      symbol: "DAI"
    },
    "0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8" => %{
      address: "0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8",
      name: "StarkGate: USDC",
      symbol: "USDC"
    },
    "0x068f5c6a61780768455de69077e07e89787839bf8166decfbf92b645209c0fb8" => %{
      address: "0x068f5c6a61780768455de69077e07e89787839bf8166decfbf92b645209c0fb8",
      name: "StarkGate: USDT",
      symbol: "USDT"
    },
    "0x04f89253e37ca0ab7190b2e9565808f105585c9cacca6b2fa6145553fa061a41" => %{
      address: "0x04f89253e37ca0ab7190b2e9565808f105585c9cacca6b2fa6145553fa061a41",
      name: "Nostra: ETH",
      symbol: "nETH"
    },
    "0x03fe2b97c1fd336e750087d68b9b867997fd64a2661ff3ca5a7c771641e8e7ac" => %{
      address: "0x03fe2b97c1fd336e750087d68b9b867997fd64a2661ff3ca5a7c771641e8e7ac",
      name: "StarkGate: wBTC",
      symbol: "WBTC"
    },
    "0x0319111a5037cbec2b3e638cc34a3474e2d2608299f3e62866e9cc683208c610" => %{
      address: "0x0319111a5037cbec2b3e638cc34a3474e2d2608299f3e62866e9cc683208c610",
      name: "StarkGate: rETH",
      symbol: "rETH"
    }
  }

  # @networks [:mainnet, :sepolia]
  # starknet_keccak("balanceOf")
  @balanceOf_selector "0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e"

  def contract_portfolio(address, :mainnet),
    do: fetch_portfolio(address, :mainnet, @whitelisted_tokens_mainnet)

  def contract_portfolio(_, _), do: []

  defp fetch_portfolio(address, network, tokens) do
    tokens
    |> Map.keys()
    |> Enum.map(fn token_address ->
      {:ok, [balance_in_wei, _]} = token_balance(token_address, address, network)
      {tokens[token_address], balance_in_wei}
    end)
    |> Enum.filter(fn {_, balance_in_wei} -> balance_in_wei != "0x0" end)
  end

  defp token_balance(token_address, address, network) do
    Rpc.call(
      "latest",
      token_address,
      @balanceOf_selector,
      network,
      [address]
    )
  end
end
