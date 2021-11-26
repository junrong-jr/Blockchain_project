//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/Ownable.sol";
import "hardhat/console.sol";
//npm install @openzeppelin/contracts
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//npm add @uniswap/v3-periphery
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

// Uniswap v3 interface
interface IUniswapRouter is ISwapRouter {
  function refundETH() external payable;
}

// Add deposit function for WETH
interface DepositableERC20 is IERC20 {
  function deposit() external payable;
}

contract TradeMiningReward is Ownable{
    address public daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; // replace pendle address
    address public wethAddress = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public uinswapV3QuoterAddress = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public uinswapV3RouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    using SafeERC20 for IERC20;
    using SafeERC20 for DepositableERC20;
    using SafeMath for uint;

    uint private rewardPerc; 
    uint private txGasUnit;
    uint public gasFee;
    uint public ethPrice = 0;
    uint public timePeriod = 4 seconds; // set to 2 weeks, 4 sec for debugging
    IERC20 daiToken = IERC20(daiAddress);
    DepositableERC20 wethToken = DepositableERC20(wethAddress);
    IQuoter quoter = IQuoter(uinswapV3QuoterAddress);
    IUniswapRouter uniswapRouter = IUniswapRouter (uinswapV3RouterAddress);


    // fix gasFee to  discourage frontrunning, if user set high gasfee and expect return from it also swap gas used is quite predictable
    //indexed for external to search for specific address event
    
    event RewardLog(address from, uint amount);
    event Claimamount(uint amount);
    event Log(string msg, uint ref);
    mapping (address => uint) lockedRewards;// locked allocated reward
    mapping (address => uint) unlockedRewards; // collectable reward
    mapping (address => uint) nextClaimDate; // track whether user claimed when unlocked
    constructor(){
        rewardPerc = 40; //set to 40%, 1 = 1%
        txGasUnit = 46666666666666; //(estimated gas used) avg transaction fee about 0.007 ether = 0.007e18 wei, assuming avg gas price is 150 wei then it is 46,666,666,666,667 gas used
    } 

    //initial plan estimate all wei to pendle value and store it as pendle value, but it will be decimal
    /* ----------------------------------Main functions------------------------------------------*/
    function claimRewardsV2()public { // imitate function claimRewards
        Claim();
        uint amount = getUnlockedBalance();
        require(amount >0, "Nothing to claim");
        clearUnlockReward();
        //console.log("Claimed in wei:", amount);
        emit Claimamount(amount);   
    }

    function swap(uint stakePerc, uint gasPrice) public{ //imitate swap function
        //do magic swap
        allocateRewards(stakePerc, gasPrice);// allocate reward
        Claim();
    }
    
    function Claim()public{ //user will call this function to claim all their unlockRewards
        if(getClaimDate() <= block.timestamp){// set new nextClaimDate & move lock to unlock
            lockToUnlock();
            setClaimDate();
        }
    }

    // should be external since swap from other contract will call this function
    function allocateRewards(uint stakePerc, uint gasPrice)public{ // gas fee * (basic + stake), allocate locked rewards after swap function
        uint amount;
        uint totalPerc = rewardPerc; 
        updateGasFee(gasPrice);
        if(getClaimDate() == 0){// check is it new user then set time for new user
            setClaimDate();
        }
        require(getClaimDate() >0, "Require allocate of claim date");
        if(stakePerc >= 2000){ // if stake more than 2000 token
            totalPerc = rewardPerc.add(10); // basic + stake
        }
        require(totalPerc <= 100, "No more than 100%");
        amount = gasFee.mul(totalPerc).div(100); // (gasPrice * txGasUnit) * (basic + stake)
        lockedRewards[msg.sender] = lockedRewards[msg.sender].add(amount); // value stored in wei
        emit RewardLog(msg.sender, lockedRewards[msg.sender]);
    }

/* ----------------------------------Should be internal function, set to public for testing purpose------------------------------------------*/

    // should be internal only called by claim
    function lockToUnlock() public{ // allocate all lock to unlock, change to external if swap() is moved out
        require(getClaimDate() < block.timestamp, "Still not unlockable");
        require(lockedRewards[msg.sender] > 0, "Nothing to unlock");
        unlockedRewards[msg.sender] = unlockedRewards[msg.sender].add(lockedRewards[msg.sender]);
        lockedRewards[msg.sender] = 0; // reset to 0 value
        emit RewardLog(msg.sender, unlockedRewards[msg.sender]);
    }
    // should be internal only called by claimRewards
    function clearUnlockReward() public{ //reward claimed, set unlockedRewards to 0
        unlockedRewards[msg.sender] = 0;
        require(unlockedRewards[msg.sender] == 0,"Reward not cleaned up");
        emit RewardLog(msg.sender, unlockedRewards[msg.sender]);
    }

    // should be internal only called when allocateRewards
    function updateGasFee(uint gasPrice)public{ 
        require(gasPrice > 0,"gas Price > 0");
        gasFee = txGasUnit.mul(gasPrice);
    }

    function setClaimDate()public{ // set next claimable date after claimed
        nextClaimDate[msg.sender] = block.timestamp.add(timePeriod);
    }

/* ----------------------------------Only owner function------------------------------------------*/
    function setRewardPerc(uint newPerc)public onlyOwner{ //only owner can set %
        require(newPerc <= 100, "No more than 100%");
        rewardPerc = newPerc;
    }

    function setTxGasUnit(uint newGas)public onlyOwner{
        txGasUnit = newGas;
    }
/* ----------------------------------All view function------------------------------------------*/
    function getLockedBalance() public view returns(uint){
        return lockedRewards[msg.sender];
    }

    function getUnlockedBalance() public view returns(uint){
        return unlockedRewards[msg.sender];
    }
    
    function getRewardPerc()public view returns(uint){
        return rewardPerc;
    }

    function getGasFee() public view returns(uint){
        return gasFee;
    }

    function getClaimDate()public view returns(uint){
        return nextClaimDate[msg.sender];
    }

    function getTxGasUnit() public view returns(uint){
        return txGasUnit;
    }

    receive() external payable {
    // accept ETH, do nothing as it would break the gas fee for a transaction
    }

}