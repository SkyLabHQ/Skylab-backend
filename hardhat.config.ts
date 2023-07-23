require('dotenv').config()
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "circomlibjs"
import './tasks';
const { MUMBAI_RPC_URL, POLYGON_RPC_URL, MY_PRIVATE_KEY, POLYGONSCAN_API_KEY } = process.env;

const config: HardhatUserConfig = {
  defaultNetwork: "localhost",
  networks: {
    hardhat: {
    },
    mumbai: {
      url: MUMBAI_RPC_URL,
      accounts: [MY_PRIVATE_KEY]
    },
    polygon: {
      url: POLYGON_RPC_URL,
      accounts: [MY_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: POLYGONSCAN_API_KEY,
  },
  solidity: "0.8.18",
};

export default config;
