# WardWard's Trade Mining Rewards Project

This project is for the CE/CZ4153 Blockchain Technology course offered during AY21/22 Semester 1 at the School of Computer Science and Engineering, Nanyang Technological University, Singapore.

## Project Deployment Requirements:
In Command Prompt, Navgating to the Project folder and install the following:
1. npm install --save-dev @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers
2. npm install @openzeppelin/contracts
3. npm add @uniswap/v3-periphery
4. npm install --save-dev solidity-coverage
   - add import "solidity-coverage" in to hardhat.config.ts

For testnet deployment, In hardhat.config file
- add your alchemy api key
- add your metamask private key
- add your etherscan api key
    
For testing/debugging locally,
 - npx hardhat node --fork [your alchemy api key] //is required so that we can get token address info
 - npx hardhat test --network local //to connect to local node for testing

## Project Details
**Project Summary:** \
For each trade a user does on Pendle’s AMM, he is entitled to retroactively receive some PENDLE rewards.

**Background & Problem Statement:** \
Trade mining works by distributing PENDLE tokens to users for each transaction they make on Pendle’s AMM. One of the biggest issues faced by users trading on DEXs like Uniswap today are the gas fees for each transaction. And lately, there has been an obscene amount up to 200 gwei or greater in average daily gas prices. 
The key benefit of Trade Mining is that it gives users the ability to offset their transaction fees by earning through trade mining rewards, which can easily trade into other cryptos or stablecoins at the user’s discretion, or they can stake it further in Pendle SingleStaking pool or other Pendle staking pools.
It is more efficient to calculate the retroactive rewards off-chain, and have some form of distribution mechanism on-chain.

**Feature Requirements:** \
Create a new TradeMiningRewards contract that can retroactively distribute rewards to trade mining participants of a Pendle Market. In addition, the contract must have the following features:
- A way to verify the trade mining incentive recipient list and recipient amount.
- A way for incentive recipients to claim their rewards.
- A trade mining epoch of every 2 weeks, where rewards are calculated over an epoch. \
*Bonuses / Nice to haves:*
- A sound trade mining reward mechanism design and gas-optimized distribution method.
- Documentation of the TradiningMiningReward contract’s specs.
- Tests must be written in Typescript.


## Project Approach & Design Explanation
Our Trade mining smart contract would reward users with Pendle tokens for each transaction they make on Pendle’s AMM. We were told to spefically target the swapExactIn and swapExactOut functions on Pendle’s AMM. Meaning our smart contract would trigger within the swapExactIn and swapExactOut transactions the user makes. \
The amount of Pendle token reward will be calculated with a formula that would be publicise. 
