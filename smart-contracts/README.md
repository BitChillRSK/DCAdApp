# BitChill - Smart Contracts

## Introduction
BitChill allows users to automate their BTC purchases at regular intervals, providing a disciplined and systematic approach to investing. The protocol supports multiple stablecoins and allows users to create, update, and delete DCA schedules, managing their investments efficiently.

## Features
1. DCA Schedules
Users can create, update, and delete DCA schedules. Each schedule defines:
   - Token: The stablecoin to be used for DCA.
   - Token balance: The amount of stablecoin to available for DCA on that schedule.
   - Purchase Amount: The amount of stablecoin to periodically convert to rBTC.
   - Purchase Period: The interval (in seconds) between each rBTC purchase.
   - Last purchase timestamp: The timestamp of the most recent purchase.  
1. Deposits and Withdrawals
   - Deposit Token: Users can deposit stablecoins into their DCA schedules.
   - Withdraw Token: Users can withdraw their stablecoins from a DCA schedule.
   - Withdraw Accumulated rBTC: Users can withdraw the rBTC accumulated through all their DCA strategies.
   - Withdraw Interest: Users can withdraw the stablecoin interest accrued by their deposits (if applicable).  
2. Batch Processing
   - The protocol supports batch processing of rBTC purchases for multiple users, optimizing gas costs and improving efficiency.
3. Fee Management
   - Fees are calculated based on the annual spending rate, with a flexible fee rate system to ensure fair charges.
4. Admin Operations 
   - Admins can perform several operations, including updating the minimum purchase period and managing the token handler factory.

## Contract Overview
### DcaManager
The DcaManager contract manages users' DCA schedules, deposits, withdrawals, and batch processing. Key functions include:

  - `createDcaSchedule`: Create a new DCA schedule.
  - `updateDcaSchedule`: Update an existing DCA schedule.
  - `deleteDcaSchedule`: Delete a DCA schedule and withdraw remaining funds.
  - `depositToken`: Deposit stablecoins into a DCA schedule.
  - `withdrawToken`: Withdraw stablecoins from a DCA schedule.
  - `withdrawRbtcFromTokenHandler`: Withdraw accumulated rBTC from a specific token handler.
  - `withdrawAllAccumulatedRbtc`: Withdraw all accumulated rBTC across all DCA schedules.
  - `batchBuyRbtc`: Perform batch rBTC purchases for multiple users.

### DocTokenHandler
The DocTokenHandler contract handles the stablecoin (DOC) deposits and manages the minting of kDOC tokens as part of the DCA process. Key functions include:

  - `depositToken`: Deposit DOC tokens and mint kDOC.
  - `buyRbtc`: Convert DOC to rBTC for a single user.
  - `batchBuyRbtc`: Convert DOC to rBTC for multiple users in a batch process.

### AdminOperations
The AdminOperations contract manages administrative operations such as updating the token handler factory.

## Testing and Security
The protocol has been thoroughly tested using Foundry, with a focus on ensuring robustness and security. Key invariant tests include:

  - `invariant_kDocContractDocBalanceEqualsSumOfAllUsers`: Ensures all the DOC deposited in the protocol by users is immediately lent on Tropykus and the amount lent in total equals the balance of all DCA schedules.

  - `invariant_DocTokenHandlerRbtcBalanceNearlyEqualsSumOfAllUsers`: Ensures the rBTC balance in the `DocTokenHandler` contract is the same as the sum of all users' purchased rBTC (with a small precision loss due to the charging of fees).

## Getting Started

### Prerequisites
Ensure you have the following installed:

- Rust
- Foundry
  
### Installation
Clone the repository and install dependencies:

```bash
git clone https://github.com/BitChillRSK/DCAdApp
cd DCAdApp
git checkout smart-contracts
```
### Deployment
Deploy the contracts using Foundry:

```bash
forge script script/DeployContracts.s.sol:DeployContracts --rpc-url  127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### Running Tests
Run the tests to ensure everything is working correctly:

```bash
forge test
```

## Contact
For any questions or issues, please contact BitChill's [Smart Contract Developer](https://www.linkedin.com/in/antonio-maria-rodriguez-ynyesto-sanchez/).

## Disclaimer
This protocol is unaudited. Use at your own risk. Always perform due diligence before interacting with smart contracts.