import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "./tasks";
import 'dotenv/config'

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    hardhat: {
      chainId: 56,
      forking: {
        url: "https://bsc-dataseed4.ninicoin.io/", // https://docs.bscscan.com/misc-tools-and-utilities/public-rpc-nodes
      }
    },
    bnb_mainnet: {
      url: "https://bsc-dataseed1.binance.org/",
      chainId: 56,
      accounts: [process.env.PRIVATE_KEY || ""]
    },
    bnb_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      accounts: [process.env.PRIVATE_KEY || ""]
    },
  },
  etherscan: {
    apiKey: {
      bnb_mainnet: 'https://api.bscscan.com/api?apikey=JMFE8Q8C179GIDB8425XJQ9F4PZ37VE5RH'
    },
    customChains: [
      {
        network: "bnb_mainnet",
        chainId: 56,
        urls: {
          apiURL: "https://api.bscscan.com/api?apikey=JMFE8Q8C179GIDB8425XJQ9F4PZ37VE5RH",
          browserURL: "https://bscscan.com/"
        }
      }
    ]
  },
  paths: {
    tests: "./test"
  }
};

export default config;
