import copy
import json
import sys
from web3 import Web3, middleware

# Resources
fuel = 25000
battery = 25000
# Mint batch size
batch_size = 20
# Mint gas scaler
max_gas_scaler = 1.4

# Skylab Tournament contract address
network_url = 'https://polygon-rpc.com/'
# network_url = 'https://rpc-mumbai.maticvigil.com'

contract_address = "0xc439f052a92736F6d0a474654ab88F737b7bD308"
# Skylab Tournament owner info
caller = "0xD0f899a62aC7ED1b4A145a111ae42D23f4cc2919"
private_key = "68eea6ece306d9cf365390211901f6226558925aae1fa31ad61632dbdd7bc261"
# caller = "0x225E5Dd7B09E24C7AE00dFe9e54CDEbAA233d5CF"
# private_key = "7a0eb778baa7e1de03f220c762b0ad42c9d0260a1b1d0a5588265696b5258f91"

def airdrop(filename):
    data_per_wallet = {}
    with open(filename, "r") as f:
        for line in f.readlines():
            user_info = json.loads(line)
            data_per_wallet[user_info["wallet"]] = user_info

    all_wallets = list(data_per_wallet.keys())
    successful_wallets = set()
    failed_wallets = set(data_per_wallet.keys())

    w3 = Web3(Web3.HTTPProvider(network_url))

    with open("../abis/SkylabTournament.abi", "r") as f:
        abi = json.load(f)
    w3.middleware_onion.inject(middleware.geth_poa_middleware, layer=0)
    contract = w3.eth.contract(address=contract_address, abi=abi)

    nonce = w3.eth.get_transaction_count(caller)
    chain_id = w3.eth.chain_id
    print(f"Current gas price {w3.eth.gas_price}")

    wallet_group = []
    try: 
        for i in range(0, len(all_wallets), batch_size):
            wallet_group = all_wallets[i:i+batch_size]
            print(f"Airdrop to {wallet_group}")

            send_txn = ""
            txn_receipt = {}
            try:
                call_function = contract.functions.tournamentMint(wallet_group, fuel, battery).build_transaction({
                    "chainId": chain_id, "from": caller, "nonce": nonce, "maxFeePerGas": int(w3.eth.gas_price * max_gas_scaler), 
                    })
                signed_txn = w3.eth.account.sign_transaction(call_function, private_key=private_key)
                send_txn = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
                txn_receipt = w3.eth.wait_for_transaction_receipt(send_txn, timeout=600)
            except Exception as e:
                print(f"FAILED with the following exception: {e}, send_txn {send_txn}, txn_receipt {txn_receipt}")
                continue

            gas_used = txn_receipt.get("gasUsed", 0) * txn_receipt.get("effectiveGasPrice", 0)
            print(f"success, used gas: {gas_used} wei")
            successful_wallets.update(wallet_group)
            failed_wallets.difference_update(wallet_group)
            nonce += 1

    finally:
        with open("failed_mints.temp", "w") as f:
            for wallet in failed_wallets:
                f.write(json.dumps(data_per_wallet[wallet]) + "\n")

        with open("successful_mints.temp", "w") as f:
            for wallet in successful_wallets:
                f.write(json.dumps(data_per_wallet[wallet]) + "\n")

        print("All done. Check results in failed_mints and successful_mints.")

if __name__ == "__main__":
    filename = "wallets.temp"
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    airdrop(filename)