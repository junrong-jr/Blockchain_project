# WardWard's Trade Mining Rewards Project

This project is for the CE/CZ4153 Blockchain Technology course offered during AY21/22 Semester 1 at the School of Computer Science and Engineering, Nanyang Technological University, Singapore.

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
Bonuses / Nice to haves:
- A sound trade mining reward mechanism design and gas-optimized distribution method.
-	Documentation of the TradiningMiningReward contract’s specs.
-	Tests must be written in Typescript.

