from ape import accounts, project
from scripts import constant
account = accounts.load('skylab')
account.set_autosign(True, passphrase="y")
def main():
    tournament = project.TrailblazerTournament.at(constant.REAL_MAINNET_TrailblazerTournament)

    all_wallets = []
    with open("scripts/wallets.temp", "r") as f:
        for wallet in f.readlines():
            all_wallets.append(wallet.strip())

    successful_wallets = set()
    failed_wallets = set(all_wallets)

    try: 
        for i in range(0, len(all_wallets), 20):
            wallet_group = all_wallets[i:i+20]
            print(f"Airdrop to {wallet_group}")

            try:
                tournament.tournamentMint(wallet_group, sender=account)
            except Exception as e:
                print(f"FAILED with the following exception: {e}")
                continue

            print(f"success")
            successful_wallets.update(wallet_group)
            failed_wallets.difference_update(wallet_group)

    finally:
        with open("scripts/failed_mints.temp", "w") as f:
            for wallet in failed_wallets:
                f.write(wallet + "\n")

        with open("scripts/successful_mints.temp", "w") as f:
            for wallet in successful_wallets:
                f.write(wallet + "\n")

        print("All done. Check results in failed_mints and successful_mints.")