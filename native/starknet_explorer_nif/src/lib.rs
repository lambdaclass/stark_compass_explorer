use rustler::types::binary::Binary;
use starknet_in_rust::felt::Felt252;
use starknet_in_rust::hash_utils;
use starknet_in_rust::utils::Address;
// This turns into {:ok, value} or {:error, "error message"} in elixir.
pub type ElixirResult<T> = Result<T, String>;
// Receives field elements as hex strings
// (without leading 0x), and returns a contract address.
#[rustler::nif]
fn contract_address(
    deployer_address: Binary,
    salt: Binary,
    class_hash: Binary,
    constructor_call_data: Vec<Binary>,
) -> ElixirResult<String> {
    let deployer_address = Address(binary_to_felt(deployer_address)?);
    let salt = binary_to_felt(salt)?;
    let class_hash = binary_to_felt(class_hash)?;
    let constructor_call_data = constructor_call_data
        .into_iter()
        .map(|call_data| binary_to_felt(call_data))
        .collect::<ElixirResult<Vec<Felt252>>>()?;
    let address = hash_utils::calculate_contract_address(
        &salt,
        &class_hash,
        &constructor_call_data,
        deployer_address,
    )
    .map_err(|err| err.to_string())?;
    let address_hex = address.to_str_radix(16_u32);
    Ok(format!("0x{}", address_hex))
}
fn binary_to_felt(binary: Binary) -> Result<Felt252, String> {
    let string = String::from_utf8((*binary).to_vec())
        .map_err(|err| format!("Invalid elixir string!, got this error {}", err))?;
    dbg!(&string);
    Ok(Felt252::from_bytes_be(string.as_bytes()))
}
rustler::init!("Elixir.StarknetExplorer.NIF", [contract_address]);
