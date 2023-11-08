from ape import project,Contract
from scripts import constant, utils, account

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}
protocol_names = ['Diamond','ComponentIndex','MercuryPilots','MercuryResources','Vault']
aviation_names = ['Diamond','TrailblazerTournament']
baby_names = ['Diamond','BabyMercs']
game_names = ['Diamond','MercuryBidTacToe']
leaderboard_names = ['PilotMileage','PilotNetPoints','PilotSessions','PilotWinStreak']

def upgrade(proxy_address, contract_name):
    ContractClass = getattr(project, contract_name)
    logic = ContractClass.deploy(sender=account.deployer)
    proxy = Contract(proxy_address,abi=constant.PROXY_ABI)
    proxy.upgradeTo(logic.address, sender=account.admin)
      
def deploy_leaderboard(contract_name, protocol_address):
    leaderboard_addresses = {}
    for contract_name in leaderboard_names:
        ContractClass = getattr(project, contract_name)
        contract = ContractClass.deploy(sender=account.deployer)
        proxy = project.LeaderBoardProxy.deploy(contract.address, constant.ADMIN, "0x", sender=account.deployer)
        leaderboard_addresses[contract_name] = proxy.address
        delegate = ContractClass.at(proxy.address)
        delegate.initialize(protocol_address,sender=account.deployer)
    return leaderboard_addresses

def deploy_diamond(names):
    cut = []
    for contract_name in names:
        ContractClass = getattr(project, contract_name)
        selector = utils.get_selector(contract_name)
        contract = ContractClass.deploy(sender=account.deployer)
        if contract_name != 'Diamond':
            cut.append((contract.address,FacetCutAction['Add'],selector))
        if contract_name == 'Diamond':
            diamond_address = contract.address
    diamond = project.Diamond.at(diamond_address)
    diamond.diamondCut(cut, '0x'+'0'*40, '0x', sender=account.deployer)
    return diamond_address

def deploy_bidtactoe():
    bidtactoe = project.BidTacToe.deploy(sender=account.deployer)
    return bidtactoe.address
def main():
    ## deploy protocol and aviation
    protocol_address = deploy_diamond(protocol_names)
    aviation_address = deploy_diamond(aviation_names)
    ## Init protocol vault
    protocol = project.Vault.at(protocol_address)
    protocol.initVault(aviation_address,sender=account.deployer)
    ## Init aviation
    aviation = project.TrailblazerTournament.at(aviation_address)
    aviation.initialize(constant.MAINNET_URI,protocol_address, sender=account.deployer)
    ## deploy babymercs
    baby_address = deploy_diamond(baby_names)
    ## Init babymercs
    baby = project.BabyMercs.at(baby_address)
    baby.initialize("BabyMercs", "BabyMercs", constant.BABY_URI, sender=account.deployer)
    ##deploy game
    game_address = deploy_diamond(game_names)
    game = project.MercuryBidTacToe.at(game_address)
    ## Init ganme
    game.initialize(protocol_address, sender=account.deployer)
    ## Deploy leaderboard
    leaderboard_addresses = deploy_leaderboard(leaderboard_names, protocol_address)
    ## Registry component index
    component_index = project.ComponentIndex.at(protocol_address)
    component_index.setValidPilotCollection(baby_address, True,sender=account.deployer)
    component_index.setValidAviation(aviation_address, True,sender=account.deployer)
    component_index.setValidGame(game_address, True,sender=account.deployer)
    component_index.setPilotMileage(leaderboard_addresses['PilotMileage'],sender=account.deployer)
    component_index.setNetPoints(leaderboard_addresses['PilotNetPoints'],sender=account.deployer)
    component_index.setPilotSessions(leaderboard_addresses['PilotSessions'],sender=account.deployer)
    component_index.setWinStreak(leaderboard_addresses['PilotWinStreak'],sender=account.deployer)
    ## write address to file
    with open('./address.temp','w') as f:
        f.write("protocol_address:"+protocol_address+"\n")
        f.write("aviation_address:"+aviation_address+"\n")
        f.write("baby_address:"+baby_address+"\n")
        f.write("game_address:"+game_address+"\n")
        f.write("leaderboard_addresses:"+str(leaderboard_addresses)+"\n")