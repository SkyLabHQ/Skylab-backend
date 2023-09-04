#!/usr/bin/env bash

cd $1_js
node generate_witness.js $1.wasm ../inputs/$2.json $1.wtns
cd ../
snarkjs groth16 prove $1_0001.zkey $1_js/$1.wtns proofs/$2.json publics/$2.json
snarkjs groth16 verify $1_verification_key.json publics/$2.json proofs/$2.json