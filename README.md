# WardWard's Trade Mining Rewards Project

This project is for the CE/CZ4153 Blockchain Technology course offered during AY21/22 Semester 1 at the School of Computer Science and Engineering, Nanyang Technological University, Singapore.

## Project Deployment Requirements:
In Command Prompt, Navgating to the Project folder and install the following:
1. npm install --save-dev @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers
2. npm install @openzeppelin/contracts
3. npm add @uniswap/v3-periphery
4. npm install --save-dev solidity-coverage

For testnet deployment, In hardhat.config file
- add your alchemy api key
- add your metamask private key
- add your etherscan api key
    
For testing/debugging locally,
 - npx hardhat node --fork [your alchemy api key] //is required so that we can get token address info
 - npx hardhat test --network local //to connect to local node for testing
 - npx hardhat coverage --testfiles "test/registry/*.ts"

## Project Details
**Project Summary:** \
For each trade a user does on Pendle’s AMM, he is entitled to retroactively receive some PENDLE rewards.

**Background & Problem Statement:** \
Trade mining works by distributing PENDLE tokens to users for each transaction they make on Pendle’s AMM. One of the biggest issues faced by users trading on DEXs like Uniswap today are the gas fees for each transaction. And lately, there has been an obscene amount up to 200 gwei or greater in average daily gas prices. The key benefit of Trade Mining is that it gives users the ability to offset their transaction fees by earning through trade mining rewards, which can easily trade into other cryptos or stablecoins at the user’s discretion, or they can stake it further in Pendle SingleStaking pool or other Pendle staking pools. It is more efficient to calculate the retroactive rewards off-chain, and have some form of distribution mechanism on-chain.

**Feature Requirements:** \
Create a new TradeMiningRewards contract that can retroactively distribute rewards to trade mining participants of a Pendle Market. In addition, the contract must have the following features:
- A way to verify the trade mining incentive recipient list and recipient amount.
- A way for incentive recipients to claim their rewards.
- A trade mining epoch of every 2 weeks, where rewards are calculated over an epoch. \
*Bonuses / Nice to haves:*
- A sound trade mining reward mechanism design and gas-optimized distribution method.
- Documentation of the TradiningMiningReward contract’s specs.
- Tests must be written in Typescript. \
*Tips:*
- Mainnet forking requires archival node access. It is therefore recommended to use Alchemy as your node provider, or run your own node.
- Gas optimized distribution by performing a merkle airdrop.

## Project Approach & Design Explanation
### Understanding of the problem
This portion is to explain how we reached our approach & design of our smart contract even though it is different to what was required in the project details. \
To be honest, when we first started off the project we did not fully understand the recommended solution to the problem. However, we understood the problem and that we needed to reward Pendel tokens to users for each transaction they make on Pendle’s AMM. Needed to calculate rewards off-chain to save on gas fee for Pendle. Needed to have a gas-optimized distribution method on-chain. We misunderstood the 2-week epoch and just took it as a timelock of 2 weeks before claiming. (We will explain more later on and you will be able to see that we clearly misunderstood.) So with that in mind, we design our smart contract for Pendle’s side to consume as little gas as possible. \
We were a bit too deep in before we realised that the recommended solution in the project details basically revolves around performing Merkle airdrops. Back then after we started we simply just thought that Merkle airdrop is just another alternative to a gas-optimized distribution method but we have already thought of our own method. However, we did not change to the Merkle airdrop method for these few reasons. Firstly, we did not see the linkage of all the project features pointing to the Merkle airdrop method (I mean it was in the tips portion, we thought it was not linked, just like a good to have kinda thing). Secondly, it did not fit into our design already. Lastly, we even compare Merkle airdrop against ours which we will talk about below and concluded that it was still okay to continue with what we have. 

### Design Approach
#### Contract trigger
Our Trade mining smart contract would reward users with Pendle tokens for each transaction they make on Pendle’s AMM. We were told to spefically target the `swapExactIn` and `swapExactOut` functions on Pendle’s AMM. Meaning our smart contract would trigger within the `swapExactIn` and `swapExactOut` transactions the user makes. We would call them both Swap transactions from here on forth.

#### Caluation of Pendle token reward
The amount of Pendle token reward should be calculated off-chain with a formula that would be publicised. However, for our contract codes, we did the calculations on-chain. \
*[Back when we first started we thought would show how would our calculation & formula works by doing it on-chain, and that it is possible somehow to do the calculation off-chain and push back as an input on-chain, and then later explain it in the documentation that it should be done that way. Unfortunately at the point of writing this, we realised that that is not possible and that our thinking for this point was erroneous ☹️. (and yes, one more feature that points towards Merkle airdrop that we notice only now.) With that being said and done, we will move forward with the erroneous thinking that the calculations could be done off-chain somehow, as that is what we through while doing the smart contract. So our thinking back then was as follows...]* \
We did not want to simply leave a blank void and say that we would calculate the reward off-chain by a server/computer, so we still did the calculation on-chain for our codes. So to simplify, the calculation can/should be done off-chain but we did it on-chain to show how would our calculation & formula works. The amount of the reward will vary according to the average Gas price during the transaction. Meaning the higher the Gas price the more the reward amount. The average gas price would be pulled from a trusted oracle. More will be explained during the code explanation.

#### 2 Week Timelock & allocation 
After the calculations, the contract would allocate the Pendel tokens to the user. \
Our first design was to lock the Pendel tokens allocated and only unlock them at a fixed time every 2 weeks. For example, the fix 2 weeks epoch will happen every alternate Monday. So essentially if a user gains the Pendel tokens on Sunday and the next day was the fixed epoch then his tokens would be unlocked as well. However, after coding that out, we realised that this way of doing things would cost the deployer of this contract a lot of transactions and therefore a lot of gas fees. As the deployer would have to call every single user that has tokens to be unlocked. And so we decided to modify in a way that would not make the deployer pay for unlocking and also to make it a bit more flexible in terms of the fix 2 weeks. \
So our actual design, for the first Swap transactions that the users make the contract would set a timelock for 2 weeks from the first reward. Any Swap transactions within the timelock will just accumulate the locked tokens but not reset the timelock. And only after the initial timelock, when the user uses the Swap transactions again it will unlock all his locked tokens and reset the 2 weeks timelock. In addition, the tokens gained during this swap transaction itself will be locked. Different examples of how it looks like will be shown through the last group of test cases. Going back, this would mean that the user will be paying for the gas fees of the unlocking of his locked tokens within the Swap transactions. But of course, the gas fees will also be accounted into the calculations for the reward tokens.

#### Claiming
The claim function would also check if your timelock is up and if it is it would unlock all the locked tokens before claiming all the unlocked tokens and lastly, resetting the timelock. Else it would just claim all the unlocked tokens without unlocking any locked tokens. So the rewarded Pendel tokens will keep accumulating until the user wants to claim them. So to incentivize the users to claim the tokens we have a method that if users have a certain amount of Pendel tokens staked, they will be allocated with more Pendel tokens as a reward during the calculation.

#### Comparison with Merkle airdrop
Our understanding of Merkle airdrop is that the deployer of this smart contract would have to deploy a Merkle airdrop contract with the list of incentive recipients their amount. And the recipients would have to claim the amount from the Merkle airdrop contract. However, every 2 weeks the deployer would have to deploy a new Merkle airdrop contract. Merkle airdrop is beneficial as the deployer would not have to individually make a transaction to each recipient and therefore the deployer would save on a lot of gas fees. So essentially, instead of the deployer spending all the gas fee it would be spread across to the recipient as they claim it. \
For our use case, we essentially also does have the same benefit by spreading the cost to the users instead of the deployer. In fact, for our use case, the deployer would not even have to spend ether to keep deploying a Merkle airdrop every 2 weeks. Low infrequent users might not benefit when using Merkle airdrop as there is a possibility that the gas fee for claiming might be higher than the rewards. But for our use case, our rewards will stack indefinitely until he wants to claim it. 
