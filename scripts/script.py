from ape import project
from scripts import constant, account
def main():
    game = project.MercuryBotTournament.at(constant.MUMBAI_BotTournament)
    game.initialize(constant.MAINNET_URI, constant.MUMBAI_PROTOCOL, sender=account.deployer)
    # game.tournamentRoundOver(sender=account.deployer)
    # game.tournamentMint("0x425A0CB30cE4a914B3fED2683f992F8B7C9e9214", gas_limit = 1000000,sender=account.deployer)
    # component_index = project.ComponentIndex.at(constant.MUMBAI_PROTOCOL)
    # component_index.setValidAviation(constant.MUMBAI_BotTournament, True, sender=account.deployer)