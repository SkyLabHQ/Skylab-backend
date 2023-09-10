import { task } from 'hardhat/config';
import { verify } from '../scripts/verify';

task('deploy_skylab_protocal')
  .addParam('contract')
  .addParam('baseurl')
  .setAction(
  async function ({ contract, baseurl }: { contract: string, baseurl: string }, hre) {
    const { ethers } = hre;
    await hre.run('compile');

    const protocal = await ethers.deployContract(contract, [baseurl]);
    await protocal.waitForDeployment();
    const resources = await ethers.deployContract("SkylabResources", [protocal.target]);
    await resources.waitForDeployment();
    const metadata = await ethers.deployContract("SkylabMetadata");
    await metadata.waitForDeployment();
    await protocal.registerResourcesAddress(resources.target);
    await protocal.registerMetadataAddress(metadata.target);

    console.log(
      `${contract} deployed to ${protocal.target} 
      SkylabResources deployed to ${resources.target}
      SkylabMetadata deployed to ${metadata.target}`
    );


    console.log(
      `npx hardhat verify --network ${network.name} ${protocal.target} ${baseurl}`
    );

    // await verify(hre, tournament.target, ["ipfs://QmbdnfyfNwbCT7zTmfwxVDUDAVS7wG4Q82B1ThKXaGEwfw/"])
    // await verify(hre, resources.target, [tournament.target])
  }
)