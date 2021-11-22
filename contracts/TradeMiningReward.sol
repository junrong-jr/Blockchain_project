//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../contracts/Ownable.sol";

contract TradeMiningReward is Ownable{

    using SafeMath for uint;
    uint rewardPerc; 
    uint gasFee;
    // fix gasFee to not encourage frontrunning by setting high gasfee and expect return from it also swap gas used is quite predictable

    struct rewardToken{
        uint amount;
        uint time;
    }
    //indexed for external to search for specific address event
    event TradeRewards(uint time, address indexed from, uint amount);
    event CollectableReward(address from, uint amount);
    event LockedReward(address indexed from, uint amount);
    mapping (address => uint) lockedRewards;// locked allocated reward
    mapping (address => uint) unlockedRewards; // collectable reward

    mapping (address => rewardToken[]) public ownerRewards; // address1 => [struct1, struct2]
    mapping (address => uint) rewardCount;  //keep track of rewards quantity
    mapping (address => uint) rewardAvilable; //reward available to collect
    rewardToken[] public rewardtokens;
    constructor(){
        rewardPerc = 400; //set to 40%, 1 = 0.1%
        gasFee = 50000; // assuming avg gas price is 100 wei * 500 gas for typical swap operation
    } 
    function allocateRewards(address from, uint amount, uint basicPerc, uint stakePerc) external{ // gas fee * (basic + stake), allocate locked rewards after swap function
        if(stakePerc >= 2000){ // if stake more than 2000 token
            basicPerc = basicPerc.add(100); // basic + stake
        }
        require(basicPerc <= 1000, "No more than 100%");
        amount = amount.mul(basicPerc); // gas fee * (basic + stake)
        lockedRewards[from] = lockedRewards[from].add(amount);
        emit LockedReward(from, lockedRewards[from]);
    }

    function claimableRewards(address from) external{ // allocate all lock to unlock
        require(lockedRewards[from] > 0, "Less than 0, can't claim");
        unlockedRewards[from] = unlockedRewards[from].add(lockedRewards[from]);
        lockedRewards[from] = 0; // reset to 0 value
        emit CollectableReward(from, unlockedRewards[from]);
    }

    function viewClaimable(address from) external view returns(uint){// external function call this to get claimble reward then xfer to user
        return unlockedRewards[from];
    }

    function setRewardPerc(uint newPerc)public onlyOwner{ //only owner can set %
        require(newPerc <= 1000, "No more than 100%");
        rewardPerc = newPerc;
    }

    function setGasPrice(uint newFee)public onlyOwner{ //only owner can set gas price
        require(newFee >= 500, "Minimum Gas Fee is 1"); // 1 wei * 500 gas used = 500
        require(newFee <= 250000, "Gas Fee too high"); // 500 wei * 500 gas used = 250000
        gasFee = newFee;
    }





    function getRewards(address from,uint _amount) internal{ //record rewards to user
        require(_amount > 0, "No reward to record");
        ownerRewards[from].push(rewardToken(_amount, block.timestamp));
        rewardCount[from] = rewardCount[from].add(1);
        emit TradeRewards(block.timestamp, from, _amount);
    }

    function calRewards(address from, uint gasused, uint rewardPercen)public{ // cal of gas reward
        uint amount;
        require(rewardPercen <= 1000, "No more than 100%");
        amount = gasused.mul(rewardPercen.div(10));
        getRewards(from, amount);
    }

    //collect available rewards when timestamp pass 2 week
    //https://ethereum.stackexchange.com/questions/39520/how-to-return-an-array-of-structs-or-an-array-of-destructured-structs-in-solid
    function collectRewards(address from) public{
        uint tempCollectable = 0;
        require(rewardCount[from] > 0, "No reward to collect");
        for(uint i=0; i< ownerRewards[from].length; i++){
            if(ownerRewards[from][i].time.add(2 weeks) >= block.timestamp){
                tempCollectable = tempCollectable.add(ownerRewards[from][i].amount);
                delete ownerRewards[from][i];
                rewardCount[from] = rewardCount[from].sub(1);
            }
        }
        rewardAvilable[from].add(tempCollectable);
        emit CollectableReward(from, rewardAvilable[from]);
    }

    function collectableRewards(address from)public view returns(uint){
        return rewardAvilable[from];
    }


    // for web3 call to input gasprice
    function gasUsed(uint gasPrice)public view returns (uint){
        return gasPrice.mul(gasleft());
    }



}