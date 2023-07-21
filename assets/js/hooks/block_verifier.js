import { ProofOptions, deserialize_proof_wasm, verify_cairo_proof_wasm, new_proof_options } from "starknet-lambda-prover";

export const BlockVerifier = function () {
    this.mounted = function () {
        let block_hash = this.el.dataset.hash
        this.pushEvent("get-block-proof", { "block_hash": block_hash }, this.GetProofCallback.bind(this))
    }

    this.GetProofCallback = function ({ public_inputs, proof }, _ref) {
        let public_inputs_bytes = Uint8Array.from(public_inputs)
        let proof_bytes = Uint8Array.from(proof)

        let proof_deserialized = deserialize_proof_wasm(proof_bytes);
        let proofOptions = new_proof_options(4, 3, 3, 1);

        let result = verify_cairo_proof_wasm(proof_deserialized, public_inputs_bytes, proofOptions);

        this.pushEvent("block-verified", { "result": result })
    }


}
