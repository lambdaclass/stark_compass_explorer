defmodule StarknetExplorer.Rpc do
  use Tesla

  plug Tesla.Middleware.BaseUrl,
       "https://starknet-mainnet.infura.io/v3/" <>
         Application.fetch_env!(:starknet_explorer, :api_key)

  plug Tesla.Middleware.JSON
end
