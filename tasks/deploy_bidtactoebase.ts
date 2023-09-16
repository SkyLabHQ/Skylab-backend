import { task } from 'hardhat/config';
import { verify } from '../scripts/verify';

task('deploy_bidtactoebase')
  .setAction(
  async (params, hre) => {
    const { ethers } = hre;
    await hre.run('compile');

    const btt = await ethers.deployContract("BidTacToe");
    await btt.waitForDeployment();
    console.log(
      `BidTacToe deployed to ${btt.target}`)

    console.log(
      `npx hardhat verify --network ${network.name} ${btt.target}`
    );
  }
)
