defmodule StarknetExplorer.Pedersen do
  use Rustler, otp_app: :starknet_explorer, crate: "pedersen"
  # @spec decode(binary, atom) :: binary
  # def decode(_b64, _opt \\ :standard), do: error()

  # @spec encode(binary, atom) :: binary
  # def encode(_s, _opt \\ :standard), do: error()

  # defp _error(), do: :erlang.nif_error(:nif_not_loaded)

  # fn caclulate_contract_hash<'a>(salt: String, class_hash: String, constructor_calldata: Vec<String>, deployer_address: String) -> NifResult<String> {
  def calculate_contract_address(salt, class_hash, constructor_calldata, deployer_address),
    do: :erlang.nif_error(:nif_not_loaded)
end
