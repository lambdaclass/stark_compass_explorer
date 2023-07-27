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
#[cfg(test)]
mod test {
    use starknet_in_rust::{felt::Felt252, hash_utils, utils::Address};

    #[test]
    fn contract_address() {
        let expected = 
            "0x04311f49b1c1e1214d3ff0189b959ecaa4c0a215903a38f310791c546441930a";
        let salt: Felt252 = Felt252::from_bytes_be(
            "0x684e2b6ce49de0cbfd96dc3a9964ca28a1013466b09e089fa1b454713ae38de".as_bytes(),
        );
        let class_hash: Felt252 = Felt252::from_bytes_be(
            "0x10455c752b86932ce552f2b0fe81a880746649b9aee7e0d842bf3f52378f9f8".as_bytes(),
        );
        let constructor_call_data: Vec<Felt252> = vec![
            Felt252::from_bytes_be(
                "0x65e4c777af8dfba3a687ccabd557be85c884e9d9927fc18176e97b9c20b5206".as_bytes()
            ),
            
            Felt252::from_bytes_be(
                "0x62f02b39508a7f3857f679b44b592e5e8500ab1d5f312a5004839b9ac1295c3".as_bytes()
            )
            
        ];
        let deployer_address = Address(Felt252::from_bytes_be("".as_bytes()));
    let address = hash_utils::calculate_contract_address(
        &salt,
        &class_hash,
        &constructor_call_data,
        deployer_address,
    ).unwrap();
    assert_eq!(format!("0x{}", address), expected)
    }
}
