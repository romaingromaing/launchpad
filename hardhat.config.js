require("@nomicfoundation/hardhat-toolbox");
require('dotenv/config');
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.12",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      saveDeployments: true,
      blockGasLimit: 21000000,

    },
    localhost: {
      live: false,
      url: "http://localhost:8545",
      saveDeployments: true,
  
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: [`0x${process.env.DEPLOYER_PRIVATE_KEY}`],
      saveDeployments: true,
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [`0x${process.env.DEPLOYER_PRIVATE_KEY}`],
      saveDeployments: true,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_APIKEY,
  },
};
