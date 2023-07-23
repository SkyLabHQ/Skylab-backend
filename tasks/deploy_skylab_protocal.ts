import { task } from 'hardhat/config';
import { verify } from '../scripts/verify';

task('deploy_skylab_protocal').setAction(
  async function (taskArgs, hre) {
    const { ethers } = hre;
    await hre.run('compile');

    const tournament = await ethers.deployContract("TrailblazerTournament", ["ipfs://QmbdnfyfNwbCT7zTmfwxVDUDAVS7wG4Q82B1ThKXaGEwfw/"]);
    await tournament.waitForDeployment();
    const resources = await ethers.deployContract("SkylabResources", [tournament.target]);
    await resources.waitForDeployment();
    const metadata = await ethers.deployContract("SkylabMetadata");
    await metadata.waitForDeployment();
    await tournament.registerResourcesAddress(resources.target);
    await tournament.registerMetadataAddress(metadata.target);

    console.log(
      `TrailblazerTournament deployed to ${tournament.target} 
      SkylabResources deployed to ${resources.target}
      SkylabMetadata deployed to ${metadata.target}`
    );

    await verify(hre, tournament.target, ["ipfs://QmbdnfyfNwbCT7zTmfwxVDUDAVS7wG4Q82B1ThKXaGEwfw/"])
    await verify(hre, resources.target, [tournament.target])
  }
)