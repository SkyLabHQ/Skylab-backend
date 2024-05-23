from ape import project
from scripts import constant, account
def main():
    # game = project.TrailblazerTournament.at(constant.Sepolia_TrailblazerTournament)
    # for i in range(5):
    #     game.tournamentMint(['0x40BA69df5c58A1106480b42aFEF78DA08860081c', '0xE75c943E63b67c2E21340F93DC156aFA80fe11cB'], sender=account.deployer)
    jar_tournament = project.MercuryJarTournament.at(constant.Sepolia_Jar_Tournament)
    for i in range(8):
        for level in range(14):
            jar_tournament.mockMint(level + 1, 100, sender=account.deployer)
    # jar_tournament.setTournamentBegin(True, sender = account.deployer)
    # component = project.ComponentIndex.at(constant.Sepolia_Protocol)
    # component.setValidAviation(constant.Sepolia_Jar_Tournament, True, sender=account.deployer)