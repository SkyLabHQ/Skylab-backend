from ape import accounts, project
from scripts import constant
contract_params = ['PilotMileage','PilotNetPoints','PilotSessions','PilotWinStreak']
account = accounts.load('skylab')
account.set_autosign(True, passphrase="y")
admin = '0x2F1f413Ed42867Db21F1882a91426960F2556648'
def main():
        for contract_name in contract_params:
            ContractClass = getattr(project, contract_name)
            contract = ContractClass.deploy(sender=account)
            proxy = project.LeaderBoardProxy.deploy(contract.address, admin, "0x", sender=account)
            print(proxy.address)
            a = ContractClass.at(proxy.address)
            a.initialize(constant.REAL_MAINNET_PROTOCOL,sender=account)