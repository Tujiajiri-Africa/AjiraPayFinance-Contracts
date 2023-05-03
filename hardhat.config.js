require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');

require('dotenv').config()
const mnemonic = process.env.MNEMONIC;
const TESTNET_ACCOUNT = process.env.TESTNET_ACCOUNT;
const MAINNET_ACCOUNT = process.env.MAINNET_ACCOUNT;
const MULTICHAIN_DEPLOYER = process.env.AJIRA_PAY_MULTICHAIN_DEPLOYER
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY
const ARBISCAN_API_KEY = process.env.ARBISCAN_API_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const INFURA_API_KEY = process.env.INFURA_API_KEY

const AJIRAPAY_TESTNET_ADDRESS = process.env.AJIRAPAY_TESTNET_ADDRESS
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "bscTestnet",
  solidity: {
    version: "0.8.4",
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
      //gas:600000000000,
      //gasPrice: 900000000000,
      //gasLimit: 900000000000,
      accounts: [TESTNET_ACCOUNT],
      allowUnlimitedContractSize: true
      // accounts: {
      //   mnemonic: mnemonic
      // }
    },
    mainnet:{
      chainId: 1,
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [MULTICHAIN_DEPLOYER],
      allowUnlimitedContractSize: true
      //networkCheckTimeout: 500000000000
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      //gas:600000000000,
      //gasPrice: 600000000000,
      //gasLimit: 6000000,
      networkCheckTimeout: 500000000000,
      accounts: [MULTICHAIN_DEPLOYER],
      //allowUnlimitedContractSize: true
      // accounts: {
      //   mnemonic: mnemonic
      // }
    },
    polygon: {
      chainId: 137,
      url: 'https://polygon-rpc.com/',
      //gasLimit: 900000000000,
      accounts: [MULTICHAIN_DEPLOYER],
      allowUnlimitedContractSize: true
    },
    kava:{
      chainId: 2222,
      url: 'https://evm.kava.io',
      accounts: [MULTICHAIN_DEPLOYER],
      allowUnlimitedContractSize: true
    },
    arbitrumOne:{
      chainId: 42161,
      url: 'https://arb1.arbitrum.io/rpc',
      accounts: [MULTICHAIN_DEPLOYER],
      allowUnlimitedContractSize: true
    },
    celo: {
      url: "https://forno.celo.org",
      accounts: {
        mnemonic: mnemonic,
        path: "m/44'/52752'/0'/0"
      },
      chainId: 42220
    },
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: {
        mnemonic: mnemonic,
        path: "m/44'/52752'/0'/0"
      },
      chainId: 44787
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
      mainnet: ETHERSCAN_API_KEY,
      bscTestnet: BSCSCAN_API_KEY,
      bsc: BSCSCAN_API_KEY,
      kava: BSCSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
      arbitrumOne: ARBISCAN_API_KEY
    },
    customChains: [
      {
        network: 'kava',
        chainId: 2222,
        urls: {
          apiURL: 'https://explorer.kava.io/api',
          browserURL: 'https://explorer.kava.io',
        },
      },
    ],
  }
};
