import { task } from 'hardhat/config';
import { verify } from '../scripts/verify';

task('deploy_bidtactoe')
  .addParam('skylabaddress')
  .setAction(
  async ({ skylabaddress }: { skylabaddress: string }, hre) => {
    const { ethers } = hre;
    await hre.run('compile');

    const hash = hre.ethers.solidityPackedKeccak256(["uint256", "uint256"], [9, 123]);
    console.log(hash);

    // const hash = hre.ethers.solidityPackedKeccak256(["address", "address", "uint256", "uint256", "uint256"], ["0x4B20993BC481177EC7E8F571CECAE8A9E22C02DB", "0x78731D3CA6B7E34AC0F824C42A7CC18A495CABAB", 100, 100, 100000000]);
    // console.log(hash);
  }
)
