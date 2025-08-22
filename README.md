# PredictX - Decentralized Prediction Market on Stacks

A decentralized prediction market smart contract built on the Stacks blockchain using Clarity smart contracts.

## Overview

PredictX allows users to:
- Create prediction markets with custom questions
- Vote on market outcomes using STX tokens
- Resolve markets through designated oracles
- Claim rewards for correct predictions

## Contract Features

- **Market Creation**: Anyone can create a market by specifying:
  - Question (up to 100 ASCII characters)
  - Deadline (in blocks)
  - Oracle address (who will resolve the market)

- **Voting**: Users can vote on markets by:
  - Choosing Yes (1) or No (2)
  - Staking STX tokens on their prediction

- **Resolution**: 
  - Only designated oracle can resolve markets
  - Markets can only be resolved after deadline
  - Resolution can be Yes (1) or No (2)

- **Rewards**:
  - Winners split the losing pool proportionally to their stake
  - Claimed rewards are tracked to prevent double claims

## Error Codes

```
ERR-NOT-OWNER (u100): Not the contract owner
ERR-MARKET-CLOSED (u101): Market is closed
ERR-MARKET-OPEN (u102): Market is still open
ERR-MARKET-NOT-FOUND (u103): Market doesn't exist
ERR-ALREADY-VOTED (u104): User already voted
ERR-NOT-RESOLVED (u105): Market not resolved yet
ERR-ALREADY-CLAIMED (u106): Reward already claimed
ERR-INVALID-VOTE (u107): Invalid vote option
ERR-NOT-ORACLE (u108): Not the designated oracle
```

## Development

Built with:
- Clarity 2.0
- Stacks blockchain
- Clarinet testing framework

## Testing

Use Clarinet to run the test suite:
```bash
clarinet test
```

## License

MIT License
