import requests
import json
from web3 import Web3

contract_address = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
eth_node_url = "http://127.0.0.1:8545"

w3 = Web3(Web3.HTTPProvider(eth_node_url))

with open("../test/out/Counter.sol/Test.json", "r") as abi_file:
    contract_abi = json.load(abi_file)["abi"]

contract = w3.eth.contract(address=contract_address, abi=contract_abi)

event_filter = contract.events.UpdateLevels.createFilter(fromBlock="latest")
while True:
    for event in event_filter.get_new_entries():
        token_id = event["args"]["tokenId"]
        print(token_id)
        
        opensea_url = f"https://api.opensea.io/v2/chain/Ethereum/contract/{contract_address}/nfts/{token_id}/refresh"
        headers = {
            "accept": "application/json",
            "X-API-KEY": "0c44945fac1e4c99bf6bad572de8b9bf"
        }
        
        response = requests.post(opensea_url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print(json.dumps(data, indent=4))
        else:
            print(f"Error: {response.status_code}")

