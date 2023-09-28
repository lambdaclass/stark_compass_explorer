extern crate rustler;
use rustler::{NifResult, Error};
use starknet_in_rust::{hash_utils::calculate_contract_address, felt::{Felt252, felt_str}, utils::Address};

rustler::init!("Elixir.Pedersen", 
              [caclulate_contract_hash]
);

#[rustler::nif]
fn caclulate_contract_hash<'a>(salt: String, class_hash: String, constructor_calldata: Vec<String>, deployer_address: String) -> NifResult<String> {
    let salt = felt_str!(salt.strip_prefix("0x").unwrap_or(&salt), 16);
    let class_hash: Felt252 = felt_str!(class_hash.strip_prefix("0x").unwrap_or(&class_hash), 16);
    let constructor_calldata: Vec<Felt252> = constructor_calldata.iter().map(|f| felt_str!(f.strip_prefix("0x").unwrap_or(&f), 16)).collect();
    let deployer_address = felt_str!(deployer_address.strip_prefix("0x").unwrap_or(&deployer_address), 16);
    
    let contract_address = calculate_contract_address(&salt, &class_hash, &constructor_calldata, Address(deployer_address));

    match contract_address {
        Ok(v) => NifResult::Ok(v.to_str_radix(16)),
        Err(err) => NifResult::Err(Error::Term(Box::new(format!("Error calculating contract address: {}", err))))
    }
}
