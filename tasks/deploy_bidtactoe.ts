import { task } from 'hardhat/config';
import { verify } from '../scripts/verify';

task('deploy_bidtactoe')
  .addParam('skylabaddress')
  .setAction(
  async ({ skylabaddress }: { skylabaddress: string }, hre) => {
    const { ethers } = hre;
    await hre.run('compile');

    const paramVerifier = await ethers.deployContract("SkylabBidTacToeParamVerifier");
    await paramVerifier.waitForDeployment();
    console.log(
      `SkylabBidTacToeParamVerifier deployed to ${paramVerifier.target}`)

    const skylabbidtactoe = await ethers.deployContract("SkylabBidTacToe", [skylabaddress, paramVerifier.target]);
    await skylabbidtactoe.waitForDeployment();
    console.log(
      `SkylabBidTacToe deployed to ${skylabbidtactoe.target}`)

    const tournamentFactory = await hre.ethers.getContractFactory('SkylabTestFlight');
    const tournament = tournamentFactory.attach(skylabaddress);
    await tournament.registerGameAddress(skylabbidtactoe.target, true);

    console.log(
      `npx hardhat verify --network ${network.name} ${skylabbidtactoe.target} ${skylabaddress} ${paramVerifier.target}`
    );

    // await verify(hre, flightRace.target, [skylabaddress, traverseVerifier.target, pathDataVerifier.target, maps.target])
  }
)
