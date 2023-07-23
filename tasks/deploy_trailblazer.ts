import { task } from 'hardhat/config';
import { verify } from '../scripts/verify';

task('deploy_trailblazer')
  .addParam('skylabaddress')
  .setAction(
  async ({ skylabaddress }: { skylabaddress: string }, hre) => {
    const { ethers } = hre;
    await hre.run('compile');

    const traverseVerifier = await ethers.deployContract("GameboardTraverseVerifier");
    await traverseVerifier.waitForDeployment();

    console.log(
      `GameboardTraverseVerifier deployed to ${traverseVerifier.target}`)
    const pathDataVerifier = await ethers.deployContract("ComputeHashPathDataVerifier");
    await pathDataVerifier.waitForDeployment();

    console.log(
      `ComputeHashPathDataVerifier deployed to ${pathDataVerifier.target}`)
    const maps = await ethers.deployContract("MapHashes");
    await maps.waitForDeployment();

    console.log(
      `MapHashes deployed to ${maps.target}`)

    const PoseidonT3 = await ethers.getContractFactory('PoseidonT3');
    const PoseidonT4 = await ethers.getContractFactory('PoseidonT4');
    const poseidonT3 = await PoseidonT3.deploy();
    const poseidonT4 = await PoseidonT4.deploy();
    console.log(
      `PoseidonT3 deployed to ${poseidonT3.target}
      PoseidonT4 deployed to ${poseidonT4.target}`)

    const FlightRace = await ethers.getContractFactory('SkylabGameFlightRace', {
      libraries: {
        PoseidonT3: poseidonT3.target,
        PoseidonT4: poseidonT4.target,
      },
    });

    const flightRace = await FlightRace.deploy(skylabaddress, traverseVerifier.target, pathDataVerifier.target, maps.target);
    console.log(`
      SkylabGameFlightRace deployed to ${flightRace.target}`)

    const tournamentFactory = await hre.ethers.getContractFactory('TrailblazerTournament');
    const tournament = tournamentFactory.attach(skylabaddress);
    await tournament.registerGameAddress(flightRace.target, true);

    console.log(
      `GameboardTraverseVerifier deployed to ${traverseVerifier.target}
      ComputeHashPathDataVerifier deployed to ${pathDataVerifier.target}
      MapHashes deployed to ${maps.target}
      SkylabGameFlightRace deployed to ${flightRace.target}`
    );

    console.log(
      `npx hardhat verify --network ${network.name} ${flightRace.target} ${skylabaddress} ${traverseVerifier.target} ${pathDataVerifier.target} ${maps.target}`
    );

    // await verify(hre, flightRace.target, [skylabaddress, traverseVerifier.target, pathDataVerifier.target, maps.target])
  }
)
