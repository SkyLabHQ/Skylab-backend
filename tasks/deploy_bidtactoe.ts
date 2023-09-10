import { task } from 'hardhat/config';
import { verify } from '../scripts/verify';

task('deploy_bidtactoe')
  .addParam('skylabaddress')
  .setAction(
  async ({ skylabaddress }: { skylabaddress: string }, hre) => {
    const { ethers } = hre;
    await hre.run('compile');

    // const btt = await ethers.deployContract("BidTacToe");
    // await btt.waitForDeployment();
    // console.log(
    //   `BidTacToe deployed to ${btt.target}`)

    // console.log(
    //   `npx hardhat verify --network ${network.name} ${btt.target}`
    // );

    const deployer = await ethers.deployContract("SkylabBidTacToeDeployer");
    await deployer.waitForDeployment();
    console.log(
      `SkylabBidTacToeDeployer deployed to ${deployer.target}`)

    const skylabbidtactoe = await ethers.deployContract("SkylabBidTacToe", [skylabaddress, deployer.target]);
    await skylabbidtactoe.waitForDeployment();
    console.log(
      `SkylabBidTacToe deployed to ${skylabbidtactoe.target}`)

    const tournamentFactory = await hre.ethers.getContractFactory('SkylabTestFlight');
    const tournament = tournamentFactory.attach(skylabaddress);
    await tournament.registerGameAddress(skylabbidtactoe.target, true);

    console.log(
      `npx hardhat verify --network ${network.name} ${skylabbidtactoe.target} ${skylabaddress} ${deployer.target}`
    );

  }
)
