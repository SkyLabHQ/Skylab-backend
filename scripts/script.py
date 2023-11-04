from ape import accounts, project
from scripts import constant
account = accounts.load('skylab')
account.set_autosign(True, passphrase="y")
def main():
    tournament = project.TrailblazerTournament.at(constant.MAINNET_AVIATION_ADDRESS)
    tournament.tournamentRoundOver(sender=account)