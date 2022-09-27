require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');

require('dotenv').config()

const mnemonic = process.env.MNEMONIC;
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY
const AJIRAPAY_TESTNET_ADDRESS = process.env.AJIRAPAY_TESTNET_ADDRESS
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "bscTestnet",
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
  	localhost: {
      url: "http://127.0.0.1:8545"
    },
    hardhat: {

    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: {mnemonic: mnemonic}
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 3000000000000000,
      accounts: {mnemonic: mnemonic}
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  },

  etherscan: {
    apiKey: {
      bscTestnet: BSCSCAN_API_KEY
    }
  }
};
