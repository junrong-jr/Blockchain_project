//const hre = require('hardhat');
//const fs = require('fs');
//import { ethers } from "ethers";

import { ethers } from "hardhat";

async function main() {

  const contractName = 'TradeMiningReward';
  //await hre.run("compile");
  const smartContract = await ethers.getContractFactory(contractName);
  const TradeMining = await smartContract.deploy();
  await TradeMining.deployed();
  console.log(`${contractName} deployed to: ${TradeMining.address}`);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });