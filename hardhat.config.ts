import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
//import "@nomiclabs/hardhat-etherscan";
import "solidity-coverage";

const Alchemy = " your alchemy api key";
const PRI_KEY = "your private key";
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


export default {
  solidity: "0.8.0",
  networks: {
    hardhat: {
      chainId: 1337,
    },
    kovan: {
      url: " your moralis api key ",
      accounts: [`0x${PRI_KEY}`],
    },

    ropsten: {
      url: "your moralis api key",
      accounts: [`0x${PRI_KEY}`],
    },

    rinkeby: {
      url: "your moralis api key",
      accounts: [`0x${PRI_KEY}`],
    },
    local: {
      url: "http://127.0.0.1:8545/",
      accounts: [`0x${PRI_KEY}`],
    },
  },
  etherscan: {
    apiKey: " your ether scan api key "
  },

};