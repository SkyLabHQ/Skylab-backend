from ape import accounts, project
import json
import os
from scripts import constant

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

cut = []

diamond_address = ''

account = accounts.load('skylab')
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
    'BabyMercs': {}
}

    
def get_selector(contract):
    file_path = f'{os.getcwd()}/out/{contract}.sol/{contract}.json'
    with open(file_path, 'r') as f:
        data = json.load(f)
        method_identifiers = data['methodIdentifiers']
        selectors = ['0x' + selector for selector in method_identifiers.values()]
        return selectors

def main():
    # for contract_name, constructor_args in contract_params.items():
    #     ContractClass = getattr(project, contract_name)
    #     selector = get_selector(contract_name)
    #     if constructor_args:
    #         contract = ContractClass.deploy(
    #             *constructor_args,
    #             sender=account
    #         )
    #     else:
    #         contract = ContractClass.deploy(sender=account)
    #     if contract_name != 'Diamond':
    #         cut.append((
    #             contract.address,
    #             FacetCutAction['Add'],
    #             selector
    #         ))
    #     if contract_name == 'Diamond':
    #         diamond_address = contract.address
    # diamond = project.Diamond.at(diamond_address)
    # diamond.diamondCut(cut, '0x'+'0'*40, '0x', sender=account)
    # aviation = project.TrailblazerTournament.at(diamond_address)
    # aviation.initialize(constant.MAINNET_URI,constant.MAINNET_PROTOCOL_ADDRESS, sender=account)
    # baby = project.BabyMercs.at(diamond_address)
    # baby.initialize("BabyMercs", "BabyMercs", constant.BABY_URI, sender=account)
    # protocol = project.Vault.at(constant.MAINNET_PROTOCOL_ADDRESS)
    # protocol.initVault(constant.MAINNET_AVIATION_ADDRESS,sender=account)
    # game = project.MercuryBidTacToe.at(constant.MERCURY_BIDTACTOE_ADDRESS)
    # game.setProtocol(constant.PROTOCOL_ADDRESS, sender=account)
    component_index = project.ComponentIndex.at(constant.MAINNET_PROTOCOL_ADDRESS)
    # component_index.setValidPilotCollection(diamond_address, True,sender=account)
    #component_index.setValidAviation(diamond_address, True,sender=account)
    # component_index.setPilotMileage('0xdF7586f7577C8F689E07f84Db70c3d64466ed28F', sender=account)
    # component_index.setNetPoints('0xC69B2aDF2Bdb983B8d930A2c52923B001aF053cd', sender=account)
    # component_index.setPilotSessions('0x043902c507651D70208A7D0174F860F9C6eaA52e', sender=account)
    component_index.setWinStreak("0xd9D8f5dD559B08184ecbb7dfE6eF0a596ffcf251", sender=account)