import fs from 'fs';
import path from 'path';
import { task } from 'hardhat/config';

const defaultContractABIExports = [
  // Protocal
  'contracts/TrailblazerTournament.sol:TrailblazerTournament',
  'contracts/SkylabResources.sol:SkylabResources',
  'contracts/SkylabGameFlightRace.sol:SkylabGameFlightRace',
  'contracts/TrailblazerLeadershipDelegation.sol:TrailblazerLeadershipDelegation',
  'contracts/SkylabBidTacToe.sol:SkylabBidTacToe',
  'contracts/BidTacToe.sol:BidTacToe'
];

task('abi:clean', 'Clean exported ABI artifacts').setAction((taskArguments, hre) => {
  return new Promise(() => {
    const outputDirectory = path.resolve(hre.config.paths.root, './abi-exports');
    if (!fs.existsSync(outputDirectory)) return null;
    fs.rmSync(outputDirectory, { recursive: true, force: true });
  });
});

task('abi:export', 'Export ABI artifacts')
  .addVariadicPositionalParam('contracts', 'Contracts to export', defaultContractABIExports)
  .setAction(async ({ contracts }: { contracts: string[] }, hre) => {
    // Get output directory and ensure it exists
    const outputDirectory = path.resolve(hre.config.paths.root, './abi-exports');
    if (!fs.existsSync(outputDirectory)) fs.mkdirSync(outputDirectory);

    // Loop through each artifact we need to export
    await Promise.all(
      contracts.map(async (contractName) => {
        // Get the artifact
        const artifact = await hre.artifacts.readArtifact(contractName);

        // Get the ABI
        let abi = artifact.abi;

        // Write to destination
        const destination = path.resolve(outputDirectory, artifact.contractName) + '.json';
        await fs.promises.mkdir(path.dirname(destination), { recursive: true });
        await fs.promises.writeFile(destination, `${JSON.stringify(abi, null, 2)}\n`, {
          flag: 'w',
        });
      }),
    );
  });
