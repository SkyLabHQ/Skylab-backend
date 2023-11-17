from ape import project
from scripts import constant, utils, account

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

zero_address = '0x'+'0'*40

protocol_params = [
    'ComponentIndex',
    'MercuryPilots',
    'MercuryResources',
    'Vault',
]

testflight_params = [
    'MercuryTestFlight'
]

trailblazer_params = [
    'TrailblazerTournament'
]

bot_tournament_params = [
    'MercuryBotTournament'
]

game_params = [
    'MercuryBidTacToe'
]

bot_params = [
    'MercuryBidTacToeBot'
]

protocol_address = ''
aviation_address = ''
game_address = ''
trailblazer_address = ''

def update_diamond(address, params):
    ## Remove selector
    facet = project.Diamond.at(address).facets()
    print("Previous facet: ",facet)
    if type(facet) == list:
        hexbytes_array = ['0x' + bytes.hex(hexbyte) for hexbyte in facet[1]]
    if type(facet) == tuple:
        hexbytes_array = ['0x' + bytes.hex(hexbyte) for facet in facet for hexbyte in facet.functionSelectors]
    print(hexbytes_array)
    cut = []
    cut.append((
        zero_address,
        FacetCutAction['Remove'],
        hexbytes_array
    ))
    project.Diamond.at(address).diamondCut(cut,zero_address, '0x', sender=account.deployer)
    ## Registry selector
    for contract_name in params:
        print(contract_name)
        ContractClass = getattr(project, contract_name)
        selector = utils.get_selector(contract_name)
        contract = ContractClass.deploy(sender=account.deployer)
        cut = []
        cut.append((
            contract.address,
            FacetCutAction['Add'],
            selector))
        diamond = project.Diamond.at(address)
        diamond.diamondCut(cut, '0x'+'0'*40, '0x',sender=account.deployer)

def main():
    network = input("please choose the network: 'Polygon', 'Mumbai' ")
    if network != 'Polygon' and network != 'Mumbai':
        print("Wrong network, must be one of these: 'Polygon', 'Mumbai'")
        return
    diamond = input("please choose the diamond: 'Protocol', 'MercuryTestFlight', 'TrailblazerTournament', 'MercuryBidTacToe', 'MercuryBidTacToeBot', 'MercuryBotTournament' ")
    if network == 'Polygon':
        protocol_address = constant.REAL_MAINNET_PROTOCOL
        trailblazer_address = constant.REAL_MAINNET_TOURNAMENT
        game_address = constant.REAL_MAINNET_GAME
    elif network == 'Mumbai':
        protocol_address = constant.MUMBAI_PROTOCOL
        game_address = constant.MUMBAI_GAME
        trailblazer_address = constant.MUMBAI_TOURNAMENT
        bot_address = constant.MUMBAI_Bot
        testflight_address = constant.MUMBAI_TESTFLIGHT
        bot_tournament = constant.MUMBAI_BotTournament
    if diamond == 'Protocol':
        update_diamond(protocol_address, protocol_params)
    elif diamond == 'MercuryBidTacToeBot':
        update_diamond(bot_address, bot_params)
    elif diamond == 'MercuryTestFlight':
        update_diamond(testflight_address, testflight_params)
    elif diamond == 'MercuryBidTacToe':
        update_diamond(game_address, game_params)
    elif diamond == 'MercuryBotTournament':
        update_diamond(bot_tournament, bot_tournament_params)
    elif diamond == 'TrailblazerTournament':
        update_diamond(trailblazer_address, trailblazer_params)