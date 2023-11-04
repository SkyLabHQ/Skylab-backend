from ape import accounts, project
import json
import os
from scripts import constant

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

protocol_address = constant.PROTOCOL_ADDRESS
game_address = constant.MAINNET_GAME_ADDRESS
aviation_address = constant.AVIATION_ADDRESS
mainnet_aviation_address = constant.MAINNET_AVIATION_ADDRESS
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
    for contract_name in game_params:
        print(contract_name)
        ContractClass = getattr(project, contract_name)
        selector = get_selector(contract_name)
        contract = ContractClass.deploy(sender=account)
        cut = []
        cut.append((
            contract.address,
            FacetCutAction['Add'],
            selector))
        diamond = project.Diamond.at(game_address)
        diamond.diamondCut(cut, '0x'+'0'*40, '0x',sender=account)
    # aviation = project.MercuryTestFlight.at(aviation_address)
    #aviation.registerMetadataURI(constant.TEST_URI,sender=account)
    # mainnet_aviation = project.TrailblazerTournament.at(mainnet_aviation_address)
    # mainnet_aviation.registerMetadataURI(constant.TEST_URI,sender=account)
    # uri = mainnet_aviation.tokenURI(13)
    # print(uri)
