from ape import accounts, project
import json
import os

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

cut = []

diamond_address = ''

account = accounts.load('deployer')

# Note: contrat_name : constructor_args
# replace it if needed
contract_params = {
    'Diamond': {},
    'ComponentIndex': {},
    'MercuryPilots': {},
    'MercuryResources': 'https://skylab.mypinata.cloud/ipfs/QmdF8YmF17JNm4LaYp4BU21rWcdoj4P6p9KN8JvqaFQpxB/',
    'Vault': '0x27c38bABAe5a8A8d0302B66120D07E3457b48058',
}

# contract_params = {
#     'Diamond': {},
#     'MercuryTestFlight': 'https://gateway.pinata.cloud/ipfs/QmdAVTVehGVNRwTxKj9Tz4utEqh4CKf2YTaA9godJAGAFu/'
# }

    
def get_selector(contract):
    file_path = f'{os.getcwd()}/out/{contract}.sol/{contract}.json'
    with open(file_path, 'r') as f:
        data = json.load(f)
        method_identifiers = data['methodIdentifiers']
        selectors = ['0x' + selector for selector in method_identifiers.values()]
        return selectors

def main():
    for contract_name, constructor_args in contract_params.items():
        ContractClass = getattr(project, contract_name)
        selector = get_selector(contract_name)
        if constructor_args:
            contract = ContractClass.deploy(
                constructor_args,
                sender=account
            )
        else:
            contract = ContractClass.deploy(sender=account)
        if contract_name != 'Diamond':
            cut.append((
                contract.address,
                FacetCutAction['Add'],
                selector
            ))
        if contract_name == 'Diamond':
            diamond_address = contract.address
    diamond = project.Diamond.at(diamond_address)
    diamond.diamondCut(cut, '0x'+'0'*40, '0x', sender=account)