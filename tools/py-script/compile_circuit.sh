circom $1.circom --r1cs --wasm --sym --c
snarkjs groth16 setup $1.r1cs ../../pot18_final.ptau $1_0000.zkey
snarkjs zkey contribute $1_0000.zkey $1_0001.zkey --name="1st Contributor Name" -v
snarkjs zkey export verificationkey $1_0001.zkey $1_verification_key.json