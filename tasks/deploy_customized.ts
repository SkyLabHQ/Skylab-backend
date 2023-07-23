import { task } from 'hardhat/config';
import { verify } from '../scripts/verify';

task('deploy_customized').setAction(
  async function (taskArgs, hre) {
    const { ethers } = hre;
    await hre.run('compile');

    // const trailblazerLeadershipDelegation = await ethers.deployContract("TrailblazerLeadershipDelegation", ["0xc439f052a92736F6d0a474654ab88F737b7bD308"]);
    // await trailblazerLeadershipDelegation.waitForDeployment();

    const tournamentFactory = await hre.ethers.getContractFactory('TrailblazerTournament');
    const tournament = tournamentFactory.attach("0xc439f052a92736F6d0a474654ab88F737b7bD308");

    const flightRaceFactory = await hre.ethers.getContractFactory('SkylabGameFlightRace', {
      libraries: {
        PoseidonT3: "0xf471e76af8ffe0f0dac847f7b5dfd38f7ebe2efd",
        PoseidonT4: "0x3924b8a5e2fde7fb5da6f83b504a4b13a8f4ee2f",
      },
    });
    const flightRace = flightRaceFactory.attach("0x5c931fe359E94B6baF4C215b9169D8F1AcfD6B91");

    for (let i = 175; i < 327; i++) {
      var level = await tournament._aviationLevels(i);
      var state = await flightRace.gameState(i);
      if (level != 1 || state != 0) {
        console.log(`${i} level = ${level} state = ${state}`)
      }
    }

  }
)