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
#     # 'ComponentIndex': {},
#     # 'MercuryPilots': {},
#     # 'MercuryResources': {},
#     # 'Vault': {},
#     'TrailblazerTournament': {}
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
    # aviation.initialize(constant.MAINNET_URI,constant.REAL_MAINNET_PROTOCOL, sender=account)
    # baby = project.BabyMercs.at(diamond_address)
    # baby.initialize("BabyMercs", "BabyMercs", constant.BABY_URI, sender=account)
    # protocol = project.Vault.at(constant.REAL_MAINNET_PROTOCOL)
    # protocol.initVault(constant.REAL_MAINNET_TrailblazerTournament,sender=account)
    # game = project.MercuryBidTacToe.at(constant.MERCURY_BIDTACTOE_ADDRESS)
    # game.setProtocol(constant.PROTOCOL_ADDRESS, sender=account)
    component_index = project.ComponentIndex.at(constant.REAL_MAINNET_PROTOCOL)
    # component_index.setValidPilotCollection(diamond_address, True,sender=account)
    component_index.setValidPilotCollection('0x79FCDEF22feeD20eDDacbB2587640e45491b757f', True,sender=account)
    component_index.setValidPilotCollection('0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03', True,sender=account)
    component_index.setValidPilotCollection('0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6', True,sender=account)
    component_index.setValidPilotCollection('0x23581767a106ae21c074b2276D25e5C3e136a68b', True,sender=account)
    component_index.setValidPilotCollection('0x70eFBA117011571c0dB83D86d1740304a8A3b79C', True,sender=account)
    # component_index.setValidAviation(constant.REAL_MAINNET_TrailblazerTournament, True,sender=account)
    component_index.setPilotMileage('0x743AC85caf73DcB362951658421116809A299b53', sender=account)
    component_index.setNetPoints('0x44A4ee1bD559A55398f8533C8c8848032Ef44305', sender=account)
    component_index.setPilotSessions('0x08Fe53530c7830173b66D89cbeb66C3260D87085', sender=account)
    component_index.setWinStreak("0xdf2b732D9fafA6D306a905b3B5BDB385280bd6a3", sender=account)