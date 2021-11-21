//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../contracts/Ownable.sol";

contract TradeMiningReward is Ownable{

    using SafeMath for uint;
    uint rewardPerc; 
    struct rewardToken{
        uint amount;
        uint time;
    }
    //indexed for external to search for specific address event
    event TradeRewards(uint time, address indexed from, uint amount);
    event CollectableReward(address from, uint amount);
    
    mapping (address => rewardToken[]) public ownerRewards; // address1 => [struct1, struct2]
    mapping (address => uint) rewardCount;  //keep track of rewards quantity
    mapping (address => uint) rewardAvilable; //reward available to collect
    rewardToken[] public rewardtokens;
    constructor(){
        rewardPerc = 1; //set to 0.1%
    }

    function getRewards(address from,uint _amount) internal{   //record rewards to user
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

    function setRewardPerc(uint newPerc)public onlyOwner{ //only owner can set %
        require(newPerc <= 1000, "No more than 100%");
        rewardPerc = newPerc;
    }

}