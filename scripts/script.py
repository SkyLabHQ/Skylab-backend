from ape import project
from scripts import constant, account
def main():
    game = project.MercuryBotTournament.at(constant.MUMBAI_BotTournament)
    game.tournamentRoundOver(sender=account.deployer)