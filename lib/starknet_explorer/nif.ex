defmodule StarknetExplorer.NIF do
  use Rustler, otp_app: :starknet_explorer, crate: "starknet_explorer_nif"

  def contract_address(_deployer_address, _salt, _class_hash, _constructor_call_data),
    do: err()

  defp err(), do: :erlang.nif_error(:nif_not_loaded)
end
