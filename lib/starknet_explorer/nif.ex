defmodule StarknetExplorer.NIF do
  use Rustler, otp_app: :starknet_explorer, crate: "starknet_explorer_nif"

  def contract_address(
        <<"0x", deployer_address::binary>>,
        <<"0x", salt::binary>>,
        <<"0x", class_hash::binary>>,
        constructor_call_data
      )
      when is_list(constructor_call_data) do
    contract_address(deployer_address, salt, class_hash, constructor_call_data)
  end

  def contract_address(_deployer_address, _salt, _class_hash, _constructor_call_data),
    do: err()

  defp err(), do: :erlang.nif_error(:nif_not_loaded)
end
