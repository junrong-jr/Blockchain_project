import { expect } from "chai";
import { ethers } from "hardhat";

/*
describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  
  });
});*/

describe("tradeMining test", () =>{
  let tradeMining, owner, addr1, addr2;

  beforeEach(async ()=> {
    const contractName = "TradeMiningReward";
    const smartContract = await ethers.getContractFactory(contractName);
    tradeMining = await smartContract.deploy();
    [owner, addr1, addr2, _] = await ethers.getSigners();
    await tradeMining.deployed();
    console.log(`${contractName} deployed to: ${tradeMining.address}`);
    const provider = ethers.provider;
  });
  
  describe("Deployment", ()=>{
    it("test", async () =>{
      expect(await tradeMining.setRewardPerc(owner)).to.equal(owner.address);
    })
  })


});