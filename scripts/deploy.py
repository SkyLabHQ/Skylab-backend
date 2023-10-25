from ape import project, accounts

def main():
    account = accounts.load('deployer')
    contract = project.load('DelegateERC721').deploy(account)
    print('Deployed to:', contract.address)