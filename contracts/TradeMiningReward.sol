//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/Ownable.sol";
//npm install @openzeppelin/contracts
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//npm add @uniswap/v3-periphery
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "hardhat/console.sol";

// Uniswap v3 interface
interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

// Add deposit function for WETH
interface DepositableERC20 is IERC20 {
    function deposit() external payable;
}

contract TradeMiningReward is Ownable {
    using SafeMath for uint256;

    uint256 private rewardPerc;
    uint256 public stakeTarget;
    uint256 public txGasUnit;
    uint256 public gasFee;
    uint256 public timePeriod = 4 seconds; // set to 2 weeks, 4 sec for debugging

    event AllocateAmount(uint256 amount);
    event ClaimAmount(uint256 amount);
    mapping(address => uint256) public lockedRewards; // allocated locked reward
    mapping(address => uint256) public unlockedRewards; // collectable reward
    mapping(address => uint256) public nextClaimDate; // Store timelock period

    constructor() {
        rewardPerc = 40; // RewardPercentage set to 40%, 1 = 1%; aka basic rewardPerc %
        txGasUnit = 46666666666666; //Amount of gas unit the swap Tx would use.
//                                   //(estimated gas used) let the estimation of avg transaction fee about 0.007ether = 0.007e18wei, assuming avg gas price is 150 wei then it is 46,666,666,666,667 gas uints used
        stakeTarget = 2000;         // target Number of Pendle tokens staked
    }

    //Everything is stored in wei. Therfore lockedRewards and unlockedRewards are stored in wei worth of Pendle tokens.

    /* ----------------------------------imitate swapExactIn and swapExactOut function (this function should be in other Pendle contract)------------------------------------------*/
    function swap(uint256 stakePerc, uint256 gasPrice) public {
        //imitate swap function
        //do magic swap
        checkUnlockable();
        allocateRewards(stakePerc, gasPrice); // allocate reward
    }

    /* ----------------------------------Main function------------------------------------------*/
    function claimRewardsV2() public {              // Users will call this function to claim unlocked tokens
        // imitate function claimRewards
        checkUnlockable();
        uint256 amount = getUnlockedBalance();
        require(amount > 0, "Nothing to claim");
        clearUnlockReward();
        emit ClaimAmount(amount);
    }

    function checkUnlockable() public {  //swap() and claimRewardsV2() will call this function
        if (getLockedBalance() > 0) {                            // if nothing to unlock skip function
            if (getClaimDate() <= block.timestamp) {            // if timelock <= time now else skip function
                // set new nextClaimDate & move lock to unlock
                lockToUnlock();
                setClaimDate();
            }
        }
    }

    /* ----------------------------------External function------------------------------------------*/
    // The follwing functions should be external since swap from other contract will call this function, set to public for testing purpose
    
    function allocateRewards(uint256 stakePerc, uint256 gasPrice) public {      //allocate locked rewards after swap function
        uint256 amount;
        uint256 totalPerc = rewardPerc;
        updateGasFee(gasPrice);
        if (getClaimDate() == 0) {            // check is it new user then set time for new user
            setClaimDate();
        }
        if (stakePerc >= stakeTarget) {       // if stake more than 2000 Pendle token
            totalPerc = rewardPerc.add(10);  // (rewardPerc %) + (stake %); stake % = 10%
        }
        require(totalPerc <= 100, "No more than 100%");
        amount = gasFee.mul(totalPerc).div(100);             // (gasFee) * (total %) is equal to (gasPrice * txGasUnit) * (rewardPerc % + stake %)
        lockedRewards[msg.sender] = lockedRewards[msg.sender].add(amount); // value stored in wei
        emit AllocateAmount(amount);
    }

    /* ----------------------------------Should be internal functions, set to public for testing purpose------------------------------------------*/

    // should be internal only called by checkUnlockable()
    function lockToUnlock() public {
        require(getClaimDate() < block.timestamp, "Still not unlockable");
        require(lockedRewards[msg.sender] > 0, "Nothing to unlock");
        unlockedRewards[msg.sender] = unlockedRewards[msg.sender].add(
            lockedRewards[msg.sender]
        );
        lockedRewards[msg.sender] = 0; // reset to 0 value
    }

    // should be internal only called by claimRewardsV2()
    function clearUnlockReward() public {
        //reward claimed, set unlockedRewards to 0
        unlockedRewards[msg.sender] = 0;
        require(unlockedRewards[msg.sender] == 0, "Reward not cleaned up");
    }

    // should be internal only called when allocateRewards
    function updateGasFee(uint256 gasPrice) public {
        require(gasPrice > 0, "gas Price > 0");
        gasFee = txGasUnit.mul(gasPrice);
    }

    function setClaimDate() public {
        // set or reset 2 weeks timelock
        nextClaimDate[msg.sender] = block.timestamp.add(timePeriod);
    }

    /* ----------------------------------Only owner function------------------------------------------*/
    function setRewardPerc(uint256 newPerc) public onlyOwner {
        //only owner can set basic rewardPerc %
        require(newPerc <= 100, "No more than 100%");
        rewardPerc = newPerc;
    }

    function setTxGasUnit(uint256 newGas) public onlyOwner {
        txGasUnit = newGas;
    }

    function setStakeTarget(uint256 newLimit) public onlyOwner {
        stakeTarget = newLimit;
    }

    /* ----------------------------------All view function------------------------------------------*/

    function getRewardPerc() public view onlyOwner returns (uint256) {
        return rewardPerc;
    }

    function getLockedBalance() public view returns (uint256) {
        return lockedRewards[msg.sender];
    }

    function getUnlockedBalance() public view returns (uint256) {
        return unlockedRewards[msg.sender];
    }

    function getClaimDate() public view returns (uint256) {
        return nextClaimDate[msg.sender];
    }

    receive() external payable {
        // accept ETH
    }
}
