from ape import accounts, project

contract_params = ['PilotMileage','PilotNetPoints','PilotSessions','PilotWinStreak']
account = accounts.load('deployer')
account.set_autosign(True, passphrase="y")
admin = '0xD0f899a62aC7ED1b4A145a111ae42D23f4cc2919'
def main():
        for contract_name in contract_params:
            ContractClass = getattr(project, contract_name)
            contract = ContractClass.deploy(sender=account)
            proxy = project.LeaderBoardProxy.deploy(contract.address, admin, "0x", sender=account)
            print(proxy.address)
            a = ContractClass.at(proxy.address)
            a.initialize("0x3a2e43c675F4da9aF823366261697d9efEFF2447",sender=account)