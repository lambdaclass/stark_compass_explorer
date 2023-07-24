use rustler::types::binary::Binary;
use starknet_in_rust::felt::Felt252;
use starknet_in_rust::hash_utils;
use starknet_in_rust::utils::Address;
pub type ElixirResult<T> = Result<T, String>;
#[rustler::nif]
fn contract_address(
    deployer_address: Binary,
    salt: Binary,
    class_hash: Binary,
    constructor_call_data: Vec<Binary>,
) -> ElixirResult<String> {
    let deployer_address = Address(Felt252::from_bytes_be(&*deployer_address));
    let salt = Felt252::from_bytes_be(&*salt);
    let class_hash = Felt252::from_bytes_be(&*class_hash);
    let constructor_call_data = constructor_call_data
        .into_iter()
        .map(|call_data| Felt252::from_bytes_be(&*call_data))
        .collect::<Vec<Felt252>>();
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

rustler::init!("Elixir.StarknetExplorer.NIF", [contract_address]);
