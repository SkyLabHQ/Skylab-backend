import { task } from 'hardhat/config';

task('register_game')
  .addParam('skylabaddress')
  .addParam('gameaddress')
  .setAction(
  async function ({ skylabaddress, gameaddress }: { skylabaddress: string, gameaddress: string }, hre) {

    const tournamentFactory = await hre.ethers.getContractFactory('TrailblazerTournament');
    const tournament = tournamentFactory.attach(skylabaddress);

    await tournament.registerGameAddress(gameaddress, true);
  }
)