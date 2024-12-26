# WellFit Token Smart Contract

A decentralized wellness rewards protocol built on Stacks blockchain using Clarity smart contracts. WellFit Token incentivizes healthy activities by providing token rewards with streak-based multipliers and time-locked challenges.

## Features

### Token Rewards System
- Activity-based token minting
- Streak multipliers for consistent participation
- Maximum reward caps for system stability
- Tiered achievement system

### Achievement Tiers
- Bronze (Default): 0-999 tokens
- Silver: 1,000-4,999 tokens
- Gold: 5,000-9,999 tokens
- Diamond: 10,000+ tokens

### Time-Locked Challenges
- Users can lock tokens for additional rewards
- 10% bonus on successful completion
- Customizable lock periods (up to ~1 year)
- Early withdrawal protection

## Smart Contract Functions

### Core Functions

`add-verifier (verifier principal) → (response bool uint)`
- Adds authorized verifiers who can validate wellness activities
- Restricted to contract owner
- Returns success or error (100)

`record-activity (user principal) (activity-type uint) (activity-points uint) → (response bool uint)`
- Records verified wellness activities
- Calculates and mints reward tokens
- Includes streak bonus calculations
- Maximum 1000 points per activity

`get-user-stats (user principal) → (optional {total-tokens: uint, activity-streak: uint, last-activity: uint, tier-level: uint})`
- Retrieves user achievement statistics
- Returns current tier level and token balance

### Challenge Functions

`lock-tokens-challenge (amount uint) (lock-period uint) → (response bool uint)`
- Initiates time-locked token challenge
- Validates token balance and lock period
- Maximum lock period: 52560 blocks (~1 year)

`claim-locked-rewards () → (response bool uint)`
- Claims completed challenge rewards
- Includes 10% bonus on successful completion
- Validates lock period completion

## Error Codes

- 100: Owner-only operation
- 101: Invalid activity
- 102: Invalid verifier
- 103: Insufficient balance
- 104: No locked rewards found
- 105: Lock period not completed
- 106: Invalid points amount
- 107: Invalid lock period

## Security Features

- Activity verification through authorized verifiers
- Maximum reward caps
- Streak validation
- Time-lock enforcement
- Owner-only administrative functions
- Safe token amount calculations

## Development Setup

1. Clone the repository
2. Install Clarinet
3. Run test suite
4. Deploy to testnet/mainnet

## Testing

```bash
clarinet test
```

## Contract Deployment

```bash
clarinet publish
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request