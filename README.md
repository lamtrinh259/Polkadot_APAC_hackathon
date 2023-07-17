# Official repo for Polkadot APAC Hackathon 2023
## Project name: Forge Habit

## Project description
We are building a habit-forming dapp with an added incentive so that users can join the challenge and hone their habits over time. The app will be built on Moonbeam and possibly Astar.

## Problem


## Solution



## User Flow


## Future Work
Some thoughts for how the whole project can be built out further:
-

## Deployed contracts


### Moonbeam mainnet (chainID: 1284)

| Contract    |                           Contract address |
| :---------- | -----------------------------------------: |
| Motivate    | insert_contract_address_here |
| DIA oracle  | insert_contract_address_here |
The verified smart contract for Moonbeam is:
<link>

### Moonbeam Alpha Testnet (chainID: 1287)

| Contract    |                           Contract address |
| :---------- | -----------------------------------------: |
| Motivate    | insert_contract_address_here |
| DIA oracle  | insert_contract_address_here |

The verified smart contract for Moonbeam Alpha Testnet is:
<link>

### Other chain (chainID: xxx)

| Contract    |                           Contract address |
| :---------- | -----------------------------------------: |
| Motivate    | insert_contract_address_here |
| DIA oracle  | insert_contract_address_here |
The verified smart contract for other chain is:


## Others

### Demo movie


### Demo site


### How to run locally
1. Go to the Frontend folder
2. Install the dependencies
```bash
pnpm install
```
3. Run the app
```bash
pnpm start
```

How to do the drawing:
1st way: point-based
For drawing, we will draw in this order:
- 1st place --> 2nd place --> 3rd place
- Each person can only win once
- Random drawing without replacement

We have 10 people in the drawing in July: at different stages of their challenges (100 points)
1. @jamesray1: 50 --> 50% chances of winning 1st place --> his marbles are gone for 2nd and 3rd place
2. @jamesray2: 20
3. remaining 8 people: 30 total

2nd way: index-based
Requirements:
- 14 days out of 21 days completed for the challenge.
- Person will be only eligible for one month, and that month will be the month when the user's challenge ends.
- For 2+ eligible players in drawing: Use Randomness from Moonbeam or DIA oracle to pick winners in this order: 1st --> 2nd --> 3rd
- Remove winner after drawing, so they don't get prize twice. (This is done by removing the index from the array)
- E.g. 10 people: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
- Edge case: 1 person --> get 1st only
- Edge case: 2 people --> drawing for 1st and 2nd person gets 2nd automatically
- Prize amount: 1st: 5% of prize pool, 2nd: 3%, 3rd: 2%. Total: 10% of prize pool each drawing.

We have: treasury and prize pool
For every failed check-in day from any user: 50% of the amount --> Treasury, and 50% --> Prize pool.
In the beginning: we will seed prize pool with 100 USDC.

If user doesn't check in for the day, we can either:
- Have admin (one of us) updates the record manually
- Or we can have a bot that updates the record automatically: Chainlink peformUpkeep() to check on the status at 23:59PM of the day.
- Update through the front-end through a bot or something.
