import copy
import json
import sys
from web3 import Web3, middleware

# Skylab Tournament contract address
network_url = 'https://polygon-rpc.com/'
# network_url = 'https://rpc-mumbai.maticvigil.com'

start_id = 175
end_id = 327
contract_address = "0xc439f052a92736F6d0a474654ab88F737b7bD308"

def main():
    w3 = Web3(Web3.HTTPProvider(network_url))

    with open("../abis/SkylabTournament.abi", "r") as f:
        abi = json.load(f)
    w3.middleware_onion.inject(middleware.geth_poa_middleware, layer=0)
    contract = w3.eth.contract(address=contract_address, abi=abi)

    for i in range(start_id, end_id):
        try:
            value = contract.functions._aviationLevels(i).call()
            if value > 1:
                print(i, value)
        except Exception as e:
            print(f"FAILED with the following exception: {e}, send_txn {send_txn}, txn_receipt {txn_receipt}")
            continue

    print("All done. ")

if __name__ == "__main__":
    main()