from ape import accounts, project

account = accounts.load('deployer')
def main():
    project.TrailblazerLeadershipDelegation.deploy("0x73b3e253DE9FBf59B08e8688a06BbC00A7c9893C", sender=account)