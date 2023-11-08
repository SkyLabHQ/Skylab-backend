from ape import accounts

admin = accounts.load('admin')
admin.set_autosign(True, passphrase=input("input your password:"))
deployer = accounts.load('skylab')
deployer.set_autosign(True, passphrase=input("input your password:"))