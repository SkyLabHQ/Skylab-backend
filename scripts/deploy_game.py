from ape import accounts, project
import json
import os

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

cut = []

diamond_address = ''

account = accounts.load('deployer')
component_index_address = '0x4783c509578161e138E94f3D3B5A91Bf9b2Ce947'
contract_params = {
    'Diamond': {},
    'MercuryBidTacToe': "0x4783c509578161e138E94f3D3B5A91Bf9b2Ce947", #protocol address
}

def get_selector(contract):
    file_path = f'{os.getcwd()}/out/{contract}.sol/{contract}.json'
    with open(file_path, 'r') as f:
        data = json.load(f)
        method_identifiers = data['methodIdentifiers']
        selectors = ['0x' + selector for selector in method_identifiers.values()]
        return selectors

def main():
    #bid_tac_toe = project.BidTacToe.deploy(sender=account)
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

    index = project.ComponentIndex.at(component_index_address)
    index.setValidGame('0xc4F184C891CB9CaEf7B913807647aCb38B05A532', True, sender=account)