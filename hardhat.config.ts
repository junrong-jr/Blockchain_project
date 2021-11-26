import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
//import "@nomiclabs/hardhat-etherscan";
import "solidity-coverage";

const Alchemy = "https://eth-kovan.alchemyapi.io/v2/FHjLShGhQ-8m7eiRzQ9CgwfGwoVlwgoO";
const Moralis = "https://speedy-nodes-nyc.moralis.io/083b34a3a4e875f3e74e50bb/eth/ropsten";
const PRI_KEY = "30e9413e6f6aba60bc59ba3623e58f47de01f6d63a6a22787c404b6a09ea1444";
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more


export default{
  solidity: "0.8.0",
  networks:{
    hardhat: {
      chainId: 1337,
    },
    kovan: {
      url: "https://speedy-nodes-nyc.moralis.io/083b34a3a4e875f3e74e50bb/eth/kovan",
      accounts: [`0x${PRI_KEY}`],
    },

    ropsten:{
      url: "https://speedy-nodes-nyc.moralis.io/083b34a3a4e875f3e74e50bb/eth/ropsten",
      accounts: [`0x${PRI_KEY}`],
    },

    rinkeby:{
      url: "https://speedy-nodes-nyc.moralis.io/083b34a3a4e875f3e74e50bb/eth/rinkeby",
      accounts: [`0x${PRI_KEY}`],
    },
    local: {
      url: "http://127.0.0.1:8545/",
      accounts: [`0x${PRI_KEY}`],
    },
  },
  etherscan: {
    apiKey: "DKD86WQJ9RAD583K31N98J4TKG87WE6MNZ"
  },

};