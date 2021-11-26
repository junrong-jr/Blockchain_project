import { Provider } from "@ethersproject/abstract-provider";
import { Signer } from "@ethersproject/abstract-signer";
import { Contract } from "@ethersproject/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("TradeMining Contract test", () =>{
  let tradeMining: Contract, owner: SignerWithAddress, addr1: SignerWithAddress, addr2: SignerWithAddress;
  const delay = (ms: number | undefined) => new Promise(res => setTimeout(res, ms));
  const delaytime = 5000;

  beforeEach(async ()=> {
    const contractName = "TradeMiningReward";
    const smartContract = await ethers.getContractFactory(contractName);
    tradeMining = await smartContract.deploy();
    await tradeMining.deployed();
    [owner, addr1, addr2] = await ethers.getSigners();
    //console.log(`${contractName} deployed to: ${tradeMining.address}`);
  });
  
  describe("Owner rights", ()=>{                            // Function tested owner(), isOwner(), transferOwner(); onlyOwner() modifier
    it("Seting the right Owner", async () =>{
      expect(await tradeMining.owner()).to.equal(owner.address);
    });

    it("Transfer of Ownership", async ()=>{
      await tradeMining.transferOwner(addr1.address);
      expect(await tradeMining.owner()).to.equal(addr1.address);  // Check addr1 is the Owner now.
      expect(await tradeMining.isOwner()).to.equal(false);        // Check if owner is still an Owner after changing it to addr1.
    });

    it("Not allowing not Owner to access", async () =>{
      await expect( tradeMining.connect(addr1).transferOwner(addr1.address) ).to.be.revertedWith("Accessible only by the owner !!");
    });

    it("allow owner to set new RewardPerc", async () =>{
      await tradeMining.setRewardPerc(50);
      expect(await tradeMining.getRewardPerc()).to.equal(50);
    });

    it("over 100% rewardPerc", async () =>{
      await expect( tradeMining.setRewardPerc(101)).to.be.revertedWith("No more than 100%");
    });

    it("allows owner to set new TxGasUnit", async () =>{
      await tradeMining.setTxGasUnit(5888888888888);
      expect(await tradeMining.getTxGasUnit()).to.equal(5888888888888);
    })
  });

  describe("Gas Fee", ()=>{     //Function tested updateGasFee(), getGasFee()
    it("Update the Gas Fee correctly", async () =>{
      await tradeMining.updateGasFee(150);
      expect(await tradeMining.getGasFee()).to.equal(150*46666666666666); //gasPrice * txGasUnit
    });
    
    it("if gasPrice is 0, throw correctly", async () =>{
      await expect(tradeMining.updateGasFee(0)).to.be.revertedWith("gas Price > 0");
    });
  });

  describe("Reward allocation", ()=>{                       // Function tested allocateRewards(), updateGasFee(), getLockedBalance();
    it("Right number of reward if StakePerc NOT achieved", async () =>{
      await tradeMining.connect(addr1).allocateRewards(1000,150);                 // Allocate to addr1
      const addr1locked = await tradeMining.connect(addr1).getLockedBalance();    // addr1 getLockedBalance
      expect(addr1locked).to.equal(2799999999999960);         // (150*46666666666666)*40/100
      //console.log("addr1 lock value is ", addr1locked);
    });
    
    it("Right number of reward if StakePerc is achieved", async () =>{
      await tradeMining.connect(addr1).allocateRewards(3000,150);
      const addr1locked = await tradeMining.connect(addr1).getLockedBalance();
      expect(addr1locked).to.equal(3499999999999950);         // (150*46666666666666)*(40+10)/100
    });  

    it("Unlocked tokens will still be 0 as time lock still active", async() =>{
      await tradeMining.connect(addr1).allocateRewards(3000,150);
      const addr1unlocked = await tradeMining.connect(addr1).getUnlockedBalance();
      expect(addr1unlocked).to.equal(0);
    });
  })

  describe("Locked tokens to unlocked tokens", () =>{       // Function tested lockToUnlock(), getUnlockedBalance(), setClaimDate()
    it("Will convert correctly", async ()=>{
      await tradeMining.connect(addr1).allocateRewards(3000,150);
      await delay(delaytime);
      await tradeMining.connect(addr1).lockToUnlock();
      expect(await tradeMining.connect(addr1).getLockedBalance()).to.equal(0);
      expect(await tradeMining.connect(addr1).getUnlockedBalance()).to.equal(3499999999999950);
    });

    it("if still not claimable will throw correctly", async ()=>{
      await tradeMining.connect(addr1).allocateRewards(3000,150);
      await expect(tradeMining.connect(addr1).lockToUnlock()).to.be.revertedWith("Still not unlockable");
    });

    it("if nothing to unlock will throw correctly", async ()=>{
      await expect(tradeMining.connect(addr1).lockToUnlock()).to.be.revertedWith("Nothing to unlock");
    });
  });


  describe("Claiming rewards", () =>{                 //Function tested claimRewardsV2() 
    it("Will Claim and reset unlock amount", async ()=>{
    await tradeMining.connect(addr1).allocateRewards(3000,150);
    await delay(delaytime);
    await expect(tradeMining.connect(addr1).claimRewardsV2()).to.emit(tradeMining, 'Claimamount')
    .withArgs(3499999999999950);
    expect(await tradeMining.connect(addr1).getUnlockedBalance()).to.equal(0);
    });

    it("If nothing to claim will throw correctly", async ()=>{
      await tradeMining.connect(addr1).allocateRewards(3000,150);
      await delay(delaytime);
      await tradeMining.connect(addr1).claimRewardsV2();
      await expect(tradeMining.connect(addr1).claimRewardsV2()).to.be.revertedWith("Nothing to claim");
    });
  });

  describe("Overall nomral use case", () =>{            //Function tested swap()
    it("With one user, swapping twice within time lock", async () => {
      await tradeMining.connect(addr1).swap(1000,150); //swap.
      await tradeMining.connect(addr1).swap(1000,150);  //swapping again within the time lock.
      await delay(delaytime);                                // waiting for time lock to end.
      await expect(tradeMining.connect(addr1).claimRewardsV2()).to.emit(tradeMining, 'Claimamount')
      .withArgs(2799999999999960 *2);
      console.log("Test claimed:", (2799999999999960 *2));  //2799999999999960 *2 /wei
    });

    /*it("With one user, swapping twice within time lock", async () => {
      await tradeMining.connect(addr1).swap(1000,150); //swap.
      await delay(delaytime);
      await tradeMining.connect(addr1).swap(1000,150);  //swapping again within the time lock.                                
      await tradeMining.connect(addr1).claimRewardsV2();
      console.log("Test claimed:", (2799999999999960))  //2799999999999960 *2 /wei
    });
    */
  });

});