from ape import project
from scripts import constant, utils, account

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

protocol_address = constant.REAL_MAINNET_PROTOCOL
game_address = constant.REAL_MAINNET_GAME
aviation_address = constant.REAL_MAINNET_TOURNAMENT
zero_address = '0x'+'0'*40

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

def main():
    for contract_name in game_params:
        print(contract_name)
        ContractClass = getattr(project, contract_name)
        selector = utils.get_selector(contract_name)
        contract = ContractClass.deploy(sender=account.deployer)
        cut = []
        cut.append((
            contract.address,
            FacetCutAction['Add'],
            selector))
        diamond = project.Diamond.at(game_address)
        diamond.diamondCut(cut, '0x'+'0'*40, '0x',sender=account.deployer)