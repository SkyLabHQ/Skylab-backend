from ape import accounts, project
from scripts import constant
account = accounts.load('skylab')
account.set_autosign(True, passphrase="y")
def main():
    skylab = '0xD0f899a62aC7ED1b4A145a111ae42D23f4cc2919'
    game = project.Diamond.at(constant.GAME_ADDRESS)
    protocol = project.Diamond.at(constant.PROTOCOL_ADDRESS)
    tournament = project.Diamond.at(constant.TOURNAMENT_ADDRESS)
    baby = project.Diamond.at(constant.BABY_ADDRESS)
    test_flight = project.Diamond.at(constant.TESTFLIGHT_ADDRESS)
    game.transferOwnership(skylab, sender=account)
    protocol.transferOwnership(skylab, sender=account)
    tournament.transferOwnership(skylab, sender=account)
    baby.transferOwnership(skylab, sender=account)
    test_flight.transferOwnership(skylab, sender=account)