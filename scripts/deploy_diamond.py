from ape import accounts, project
import json
import os

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

cut = []

diamond_address = ''

account = accounts.load('deployer')
account.set_autosign(True, passphrase="y")

# Note: contrat_name : constructor_args
# replace it if needed
# contract_params = {
#     'Diamond': {},
#     'ComponentIndex': {},
#     'MercuryPilots': {},
#     'MercuryResources': {},
#     'Vault': {},
# }

contract_params = {
    'Diamond': {},
    'MercuryTestFlight': {}
}

    
def get_selector(contract):
    file_path = f'{os.getcwd()}/out/{contract}.sol/{contract}.json'
    if contract == 'MercuryPilots':
        file_path = f'{os.getcwd()}/out/protocol/{contract}.sol/{contract}.json'
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
                *constructor_args,
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
    test_fight = project.MercuryTestFlight.at(diamond_address)
    test_fight.initialize('https://gateway.pinata.cloud/ipfs/QmdAVTVehGVNRwTxKj9Tz4utEqh4CKf2YTaA9godJAGAFu/','0x3a2e43c675F4da9aF823366261697d9efEFF2447',sender=account)
    protocol = project.Vault.at('0x3a2e43c675F4da9aF823366261697d9efEFF2447')
    protocol.initVault(diamond_address,sender=account)
    # game = project.MercuryBidTacToe.at('0xe32F3e4EF36019639312B5899F8024ba3d24d213')
    # game.setProtocol('0x3a2e43c675F4da9aF823366261697d9efEFF2447', sender=account)