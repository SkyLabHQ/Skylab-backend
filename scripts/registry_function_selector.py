from ape import accounts, project
import json
import os
from scripts import constant

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

protocol_address = constant.REAL_MAINNET_PROTOCOL
game_address = constant.REAL_MAINNET_GAME
aviation_address = constant.REAL_MAINNET_TrailblazerTournament
zero_address = '0x'+'0'*40

account = accounts.load('skylab')
account.set_autosign(True, passphrase="y")

# Note: contrat_name : constructor_args
# replace it if needed
protocol_params = [
    'ComponentIndex',
    'MercuryPilots',
    'MercuryResources',
    'Vault',
]

aviation_params = [
    'MercuryTestFlight'
]

mainnet_aviation_params = [
    'TrailblazerTournament'
]

game_params = [
    'MercuryBidTacToe'
]

def get_selector(contract):
    file_path = f'{os.getcwd()}/out/{contract}.sol/{contract}.json'
    with open(file_path, 'r') as f:
        data = json.load(f)
        method_identifiers = data['methodIdentifiers']
        selectors = ['0x' + selector for selector in method_identifiers.values()]
        return selectors

def main():
    for contract_name in protocol_params:
        print(contract_name)
        ContractClass = getattr(project, contract_name)
        selector = get_selector(contract_name)
        contract = ContractClass.deploy(sender=account)
        cut = []
        cut.append((
            contract.address,
            FacetCutAction['Add'],
            selector))
        diamond = project.Diamond.at(protocol_address)
        diamond.diamondCut(cut, '0x'+'0'*40, '0x',sender=account)