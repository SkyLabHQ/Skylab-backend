from ape import project
from scripts import constant, account
from web3 import Web3
import random

def print_gas_used_summary(transactions):
        for function_name, index, tx_hash in transactions:
            gas_used = tx_hash.gas_used
            print(f"{function_name} [{index}]: gas_used={gas_used}")
def surrender():
    game = project.MercuryBidTacToe.at(constant.Sepolia_Game)
    bidtactoeAddress = game.gamePerPlayer(account.deployer, sender=account.deployer)
    bidtactoe = project.BidTacToe.at(bidtactoeAddress)
    bidtactoe.surrender(sender=account.deployer)

def playerCreatedGameOrQueued(player):
    game = project.MercuryBidTacToe.at(constant.Sepolia_Game)
    aviation = game.burnerAddressToAviation(player, sender=player)
    return game.gamePerPlayer(player, sender=player) != '0x0000000000000000000000000000000000000000' or game.defaultGameQueue(aviation, sender=player) == player

def main():
    # surrender()
    aviation = project.TrailblazerTournament.at(constant.Sepolia_TrailblazerTournament)
    tournamentMint_hash = aviation.tournamentMint([account.deployer, account.admin], sender=account.deployer).await_confirmations()
    game = project.MercuryBidTacToe.at(constant.Sepolia_Game)
    createOrJoinDefault_hash = ''
    createOrJoinDefault_another_hash = ''
    if playerCreatedGameOrQueued(account.deployer) == False:
        createOrJoinDefault_hash = game.createOrJoinDefault(sender=account.deployer).await_confirmations()
    if playerCreatedGameOrQueued(account.skylab) == False:
        createOrJoinDefault_another_hash = game.createOrJoinDefault(sender=account.skylab).await_confirmations()
    # game.activeQueueTimeout(sender=account.deployer).await_confirmations()
    setActiveQueue_hash = game.setActiveQueue(sender=account.deployer).await_confirmations()
    setActiveQueue_another_hash = game.setActiveQueue(sender=account.skylab).await_confirmations()

    bidtactoeAddress = game.gamePerPlayer(account.deployer, sender=account.deployer)
    bidtactoe = project.BidTacToe.at(bidtactoeAddress)
    types = ["uint256", "uint256"]
    salt = 1
    playerA_bid = 9
    playerB_bid = 8
    playerA_values = [playerA_bid, salt]
    playerA_packed_hash = Web3.solidity_keccak(types, playerA_values)
    playerB_values = [playerB_bid, salt]
    playerB_packed_hash = Web3.solidity_keccak(types, playerB_values)
    hash_list = [
        ("tournamentMint", 1, tournamentMint_hash),
        ("createOrJoinDefault (deployer)", 1, createOrJoinDefault_hash),
        ("createOrJoinDefault (skylab)", 1, createOrJoinDefault_another_hash),
        ("setActiveQueue (deployer)", 1, setActiveQueue_hash),
        ("setActiveQueue (skylab)", 1, setActiveQueue_another_hash),
    ]
    for i in range(9):
        if bidtactoe.gameStates(account.deployer, sender=account.deployer) != 3 and bidtactoe.gameStates(account.skylab, sender=account.skylab) != 3:
            if bidtactoe.gameStates(account.deployer, sender=account.deployer) == 1 and bidtactoe.gameStates(account.skylab, sender=account.skylab) == 1:
                commitBid_hash = bidtactoe.commitBid(playerA_packed_hash, sender=account.deployer).await_confirmations()
                hash_list.append(("commitBid (deployer)", i+1, commitBid_hash))
                commitBid_hash = bidtactoe.commitBid(playerB_packed_hash, sender=account.skylab).await_confirmations()
                hash_list.append(("commitBid (skylab)", i+1, commitBid_hash))
                random_reveal = random.randrange(0, 2)
                if random_reveal == 1:
                    revealBid_hash = bidtactoe.revealBid(playerA_bid, salt, sender=account.deployer).await_confirmations()
                    hash_list.append(("revealBid (deployer)", i+1, revealBid_hash))
                    bidtactoe.revealBid(playerB_bid, salt, sender=account.skylab).await_confirmations()
                    hash_list.append(("revealBid (skylab)", i+1, revealBid_hash))
                else:
                    revealBid_hash = bidtactoe.revealBid(playerB_bid, salt, sender=account.skylab).await_confirmations()
                    hash_list.append(("revealBid (skylab)", i+1, revealBid_hash))
                    bidtactoe.revealBid(playerA_bid, salt, sender=account.deployer).await_confirmations()
                    hash_list.append(("revealBid (deployer)", i+1, revealBid_hash))
                print_gas_used_summary(hash_list)