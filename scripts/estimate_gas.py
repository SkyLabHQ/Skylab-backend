from ape import project
from scripts import constant, account
from web3 import Web3
import random

def print_gas_used_summary(transactions):
        for function_name, index, tx_hash in transactions:
            gas_used = tx_hash.gasUsed
            print(f"{function_name} [{index}]: gas_used={gas_used}")
def surrender():
    game = project.MercuryBidTacToe.at(constant.Sepolia_Game)
    bidtactoeAddress = game.gamePerPlayer(account.deployer, sender=account.deployer)
    bidtactoe = project.BidTacToe.at(bidtactoeAddress)
    bidtactoe.surrender(sender=account.deployer)
def main():
    # surrender()
    aviation = project.TrailblazerTournament.at(constant.Sepolia_TrailblazerTournament)
    tournamentMint_hash = aviation.tournamentMint([account.deployer, account.admin], sender=account.deployer)
    game = project.MercuryBidTacToe.at(constant.Sepolia_Game)
    createOrJoinDefault_hash = game.createOrJoinDefault(sender=account.deployer)
    createOrJoinDefault_another_hash = game.createOrJoinDefault(sender=account.skylab)
    setActiveQueue_hash = game.setActiveQueue(sender=account.deployer)
    setActiveQueue_another_hash = game.setActiveQueue(sender=account.skylab)

    bidtactoeAddress = game.gamePerPlayer(account.deployer, sender=account.deployer)
    bidtactoe = project.BidTacToe.at(bidtactoeAddress)
    types = ["uint256", "uint256"]
    salt = 1
    bid = 9
    values = [bid, salt]
    packed_hash = Web3.solidity_keccak(types, values)
    hash_list = [
        ("tournamentMint", 1, tournamentMint_hash),
        ("createOrJoinDefault (deployer)", 1, createOrJoinDefault_hash),
        ("createOrJoinDefault (skylab)", 1, createOrJoinDefault_another_hash),
        ("setActiveQueue (deployer)", 1, setActiveQueue_hash),
        ("setActiveQueue (skylab)", 1, setActiveQueue_another_hash),
    ]
    for i in range(9):
        commitBid_hash = bidtactoe.commitBid(packed_hash, sender=account.deployer)
        hash_list.append(("commitBid (deployer)", i+1, commitBid_hash))
        commitBid_hash = bidtactoe.commitBid(packed_hash, sender=account.skylab)
        hash_list.append(("commitBid (skylab)", i+1, commitBid_hash))
        revealBid_hash = bidtactoe.revealBid(bid, salt, sender=account.deployer)
        hash_list.append(("revealBid (deployer)", i+1, revealBid_hash))
        bidtactoe.revealBid(bid, salt, sender=account.skylab)
        hash_list.append(("revealBid (skylab)", i+1, revealBid_hash))

    print_gas_used_summary(hash_list)