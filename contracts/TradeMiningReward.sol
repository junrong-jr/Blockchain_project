//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
//kovan testnet
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../contracts/Ownable.sol";
import "hardhat/console.sol";
//npm install @openzeppelin/contracts
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
    uint private gasFee;
    uint public ethPrice = 0;
    IERC20 daiToken = IERC20(daiAddress);
    DepositableERC20 wethToken = DepositableERC20(wethAddress);
    IQuoter quoter = IQuoter(uinswapV3QuoterAddress);
    IUniswapRouter uniswapRouter = IUniswapRouter (uinswapV3RouterAddress);


    // fix gasFee to not encourage frontrunning by setting high gasfee and expect return from it also swap gas used is quite predictable


    //indexed for external to search for specific address event
    
    event CollectableReward(address from, uint amount);
    event LockedReward(address indexed from, uint amount);
    event Log(string msg, uint ref);
    mapping (address => uint) lockedRewards;// locked allocated reward
    mapping (address => uint) unlockedRewards; // collectable reward

    constructor(){
        rewardPerc = 400; //set to 40%, 1 = 0.1%
        gasFee = 50000; // assuming avg gas price is 100 wei * 500 gas for typical swap operation
    } 

    //function gasfee to pendle(from,amount,basicperc,stakeprc) return (pendle token amount)
    //initial plan estimate all wei to pendle value and store it as pendle value, but it will be decimal
    function allocateRewards(address from, uint amount, uint basicPerc, uint stakePerc) internal{ // gas fee * (basic + stake), allocate locked rewards after swap function
        if(stakePerc >= 2000){ // if stake more than 2000 token
            basicPerc = basicPerc.add(100); // basic + stake
        }
        require(basicPerc <= 1000, "No more than 100%");
        amount = amount.mul(basicPerc); // gas fee * (basic + stake)
        lockedRewards[from] = lockedRewards[from].add(amount); // value stored in wei
        emit LockedReward(from, lockedRewards[from]);
    }

    function claimableRewards(address from) external{ // allocate all lock to unlock
        require(lockedRewards[from] > 0, "Less than 0, can't claim");
        unlockedRewards[from] = unlockedRewards[from].add(lockedRewards[from]);
        lockedRewards[from] = 0; // reset to 0 value
        emit CollectableReward(from, unlockedRewards[from]);
    }

    function claimedRewards(address from) internal{
        unlockedRewards[from] = 0;
        require(unlockedRewards[from] == 0,"Reward not cleaned up");
    }
    function viewlocked(address from) public view returns(uint){
        return lockedRewards[from];
    }
    function viewClaimable(address from) public view returns(uint){// external function call this to get claimble reward then xfer to user
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


    function getWethBalance() public view returns(uint) {
        return wethToken.balanceOf(address(this));
    }
    function updateEthPriceUniswap() public returns(uint) {
        uint ethPriceRaw = quoter.quoteExactOutputSingle(daiAddress,wethAddress,3000,100000,0);
        ethPrice = ethPriceRaw / 100000;
        return ethPrice;
    }
    function claimRewards(address from) public { // convert wei to pendle(dai)
        address recipient = address(this);
        uint256 deadline = block.timestamp + 15;
        uint256 amountOut = viewClaimable(from).div(1 ether); // includes 18 decimals
        uint256 amountInMaximum = 10 ** 28 ;
        uint160 sqrtPriceLimitX96 = 0;
        uint24 fee = 3000;
        require(wethToken.approve(address(uinswapV3RouterAddress), amountOut), "WETH approve failed");
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
        wethAddress,
        daiAddress,
        fee,
        recipient,
        deadline,
        amountOut,
        amountInMaximum,
        sqrtPriceLimitX96
        );
        uniswapRouter.exactOutputSingle(params);
        uniswapRouter.refundETH();
        claimedRewards(from);
    }

    function wrapETH() public onlyOwner{
        uint ethBalance = address(this).balance; //address(this) is contract address
        require(ethBalance > 0, "No ETH available to wrap");
        emit Log("wrapETH", ethBalance);
        wethToken.deposit{ value: ethBalance }();
    }
    receive() external payable {
    // accept ETH, do nothing as it would break the gas fee for a transaction
    }


    /*
    struct rewardToken{
    uint amount;
    uint time;
    }
    event TradeRewards(uint time, address indexed from, uint amount);
    mapping (address => rewardToken[]) public ownerRewards; // address1 => [struct1, struct2]
    mapping (address => uint) rewardCount;  //keep track of rewards quantity
    mapping (address => uint) rewardAvilable; //reward available to collect
    rewardToken[] public rewardtokens;


    // old ideas
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
    */


}