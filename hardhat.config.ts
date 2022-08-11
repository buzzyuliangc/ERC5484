import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-web3";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "solidity-coverage";
import "dotenv/config";
import "hardhat-gas-reporter";
import { HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0 // hardhat london fork error fix for coverage
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/f4dd6db18a6f4ea98151892c0fa8e074",
      chainId: 4,
      //accounts: [process.env.PRIVATE_KEY_testnet]
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/f4dd6db18a6f4ea98151892c0fa8e074",
      chainId: 1,
      //accounts: [process.env.PRIVATE_KEY_mainnet]
    }
  },
  paths: {
    sources: "./src/*",
    artifacts: "./build",
    tests: "./src/tests/*"
  },
  gasReporter: {
    enabled: true,
    currency: "USD"
  },
  abiExporter: {
    path: "./abi",
    clear: true,
    flat: true
  }
};

export default config;
