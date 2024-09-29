from ape import project
from scripts import constant, account
def main():
    game = project.MercuryLeagueTournament.at(constant.Sepolia_League_Tournament)
    user = '0x40BA69df5c58A1106480b42aFEF78DA08860081c'
    address_zero = '0x0000000000000000000000000000000000000000'
    bytes_zero = b'\x00' * 32  # 32 bytes of zeros
    # Mint 10 planes
    for _ in range(10):
        game.mint(user, address_zero, 0, bytes_zero, value="0.02 ether", sender=account.deployer)
