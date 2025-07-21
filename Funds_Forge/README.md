# FundForge

A decentralized crowdfunding platform built on the Stacks blockchain using Clarity smart contracts. FundForge enables creators to launch funding campaigns with milestone-based checkpoint systems, ensuring accountability and transparency in project development.

##  Features

- **Campaign Creation**: Launch crowdfunding campaigns with customizable funding targets and checkpoints
- **Milestone-Based Funding**: Campaigns are structured around checkpoints that must be achieved for fund release
- **Automatic Refunds**: Built-in refund mechanism for failed or expired campaigns
- **Decentralized**: Fully on-chain with no intermediaries
- **Transparent**: All transactions and campaign states are publicly verifiable
- **Time-Bounded**: Campaigns have configurable deadlines to ensure timely execution

##  How It Works

### Campaign Lifecycle

1. **Launch**: Campaign owners create campaigns with:
   - Funding target amount (STX)
   - Number of checkpoints (1-10)
   - Campaign duration (in blocks)

2. **Backing**: Supporters can back active campaigns by sending STX tokens

3. **Milestones**: Campaign owners achieve checkpoints to unlock fund withdrawal

4. **Completion**: Once all checkpoints are met, owners can claim proportional funds

5. **Refunds**: If campaigns fail or expire, backers can withdraw their contributions

### Smart Contract Functions

#### Public Functions

- `launch-campaign(target, checkpoints, timeframe)` - Create a new funding campaign
- `back-campaign(campaign-id, amount)` - Support a campaign with STX tokens
- `achieve-checkpoint(campaign-id)` - Mark a checkpoint as completed (owner only)
- `claim-funds(campaign-id)` - Withdraw earned funds (owner only)
- `withdraw-backing(campaign-id)` - Get refund for failed campaigns (backers only)

#### Campaign States

- `STATE-LIVE` (1) - Campaign is active and accepting funds
- `STATE-SUCCESSFUL` (2) - All checkpoints completed
- `STATE-CANCELED` (3) - Campaign canceled, refunds available
- `STATE-TIMEOUT` (4) - Campaign expired

##  Technical Specifications

### Built With

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity
- **Token Standard**: STX (native Stacks tokens)

### Contract Architecture

```clarity
;; Core Data Structures
campaigns: map<uint, CampaignData>
backers: map<{campaign-id: uint, supporter: principal}, uint>

;; Key Validation Functions
- is-valid-target()
- is-valid-checkpoints()  
- is-valid-timeframe()
- is-live()
- is-expired()
```

### Security Features

- Input validation for all parameters
- Authorization checks for owner-only functions
- Automatic expiration handling
- Safe fund transfer mechanisms
- Comprehensive error handling

##  Installation & Deployment

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Setup

1. Clone the repository:
```bash
git clone https://github.com/your-username/fundforge
cd fundforge
```

2. Initialize Clarinet project:
```bash
clarinet new fundforge
cd fundforge
```

3. Add the contract:
```bash
# Copy the FundForge contract to contracts/fundforge.clar
```

4. Test the contract:
```bash
clarinet check
clarinet test
```

### Deployment

Deploy to Stacks testnet:
```bash
clarinet deploy --testnet
```

Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

##  Testing

### Unit Tests

The contract includes comprehensive test coverage for:

- Campaign creation validation
- Funding mechanisms
- Checkpoint progression
- Fund withdrawal logic  
- Refund scenarios
- Edge cases and error conditions

Run tests:
```bash
clarinet test
```

### Test Scenarios

1. **Happy Path**: Complete campaign lifecycle
2. **Validation Tests**: Invalid inputs and edge cases
3. **Authorization Tests**: Unauthorized access attempts
4. **Expiration Tests**: Time-based campaign expiry
5. **Refund Tests**: Failed campaign refund mechanisms

##  Usage Examples

### Creating a Campaign

```clarity
;; Launch a campaign for 1000 STX with 3 checkpoints, lasting 4320 blocks (~30 days)
(contract-call? .fundforge launch-campaign u1000 u3 u4320)
```

### Backing a Campaign

```clarity
;; Back campaign #0 with 100 STX
(contract-call? .fundforge back-campaign u0 u100)
```

### Completing Checkpoints

```clarity
;; Campaign owner marks checkpoint as achieved
(contract-call? .fundforge achieve-checkpoint u0)
```

##  Security Considerations

- **Fund Safety**: All STX transfers use secure built-in functions
- **Access Control**: Owner-only functions are properly protected
- **State Management**: Campaign states prevent unauthorized actions
- **Input Validation**: All inputs are validated before processing
- **Reentrancy Protection**: Contract design prevents reentrancy attacks

##  Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Write comprehensive tests for new features
- Follow Clarity best practices
- Update documentation for any API changes
- Ensure all tests pass before submitting

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)

##  Support

For questions, issues, or contributions:

- Open an issue on GitHub
- Join our Discord community
- Follow us on Twitter [@FundForge](https://twitter.com/fundforge)

---

**Built on Stacks blockchain**