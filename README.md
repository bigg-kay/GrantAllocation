# GrantAllocation

GrantAllocation is a transparent research funding platform for academic project prioritization and resource distribution built on the Stacks blockchain using Clarity smart contracts.

## Overview

This decentralized platform enables transparent and democratic allocation of research funding through a comprehensive system that manages grant pools, proposal submissions, community voting, and fund distribution. The system promotes accountability and fairness in academic research funding.

## Features

### Core Functionality
- **Grant Pool Management**: Administrators can create funding pools with specified budgets and voting periods
- **Proposal Submission**: Researchers can submit detailed project proposals requesting specific funding amounts
- **Democratic Voting**: Community members vote on proposals to guide funding decisions
- **Fund Allocation**: Transparent distribution of approved funding to researchers
- **Researcher Profiles**: Reputation tracking and profile management for academic researchers
- **Administrator Controls**: Role-based access control for grant and fund management

### Key Capabilities
- Transparent tracking of all funding decisions and allocations
- Prevention of double voting through blockchain verification
- Automatic validation of funding availability before approval
- Researcher reputation scoring based on successful project completion
- Real-time status tracking for grants and proposals
- Comprehensive audit trail for all transactions

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity 2.0
- **Contract Version**: 1.0.0
- **Epoch**: 2.5

### Data Structures

#### Grants
- Grant ID, title, and description
- Total funds and allocated amounts
- Creator information and timestamps
- Voting period and status tracking

#### Proposals
- Associated grant ID and researcher details
- Project description and requested funding amount
- Vote counts and approval status
- Submission timestamps

#### Researchers
- Profile information (name, institution)
- Reputation scoring system
- Grant history and success metrics

## Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) for Clarity development
- [Node.js](https://nodejs.org/) and npm
- [Stacks CLI](https://docs.stacks.co/docs/write-smart-contracts/cli-wallet-quickstart)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd GrantAllocation
```

2. Navigate to the contract directory:
```bash
cd GrantAllocation_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

5. Run tests:
```bash
clarinet test
```

## Usage Examples

### Initialize the Contract

```clarity
;; Initialize contract (owner only)
(contract-call? .GrantAllocation initialize)
```

### Create a Grant Pool

```clarity
;; Create a new grant with 1000 STX budget and 100 block voting period
(contract-call? .GrantAllocation create-grant
    "AI Research Grant 2024"
    "Funding for artificial intelligence research projects focusing on healthcare applications"
    u1000000000
    u100)
```

### Submit a Research Proposal

```clarity
;; Submit proposal for grant ID 1
(contract-call? .GrantAllocation submit-proposal
    u1
    "Machine Learning for Drug Discovery"
    "This project aims to develop ML algorithms for accelerating pharmaceutical research..."
    u250000000)
```

### Vote on Proposals

```clarity
;; Vote for proposal ID 1
(contract-call? .GrantAllocation vote-on-proposal u1)
```

### Register as a Researcher

```clarity
;; Register researcher profile
(contract-call? .GrantAllocation register-researcher
    "Dr. Jane Smith"
    "University of Technology")
```

## Contract Functions Documentation

### Public Functions

#### Administrative Functions
- `initialize()` - Initialize contract owner as administrator
- `set-administrator(admin, is-admin)` - Add/remove administrators (owner only)
- `create-grant(title, description, total-funds, voting-duration)` - Create new grant pool
- `approve-proposal(proposal-id)` - Approve proposal for funding (admin only)
- `distribute-funds(proposal-id)` - Distribute funds to approved proposals
- `close-grant(grant-id)` - Close grant voting period

#### User Functions
- `submit-proposal(grant-id, title, description, requested-amount)` - Submit research proposal
- `vote-on-proposal(proposal-id)` - Vote on a specific proposal
- `register-researcher(name, institution)` - Register researcher profile

### Read-Only Functions

#### Information Retrieval
- `get-grant(grant-id)` - Retrieve grant information
- `get-proposal(proposal-id)` - Retrieve proposal details
- `get-researcher(researcher)` - Get researcher profile
- `is-administrator(user)` - Check administrator status
- `has-voted(voter, proposal-id)` - Check voting status
- `get-total-grants()` - Get total number of grants
- `get-total-proposals()` - Get total number of proposals
- `get-remaining-funds(grant-id)` - Calculate remaining grant funds

## Deployment Guide

### Testnet Deployment

1. Configure Clarinet for testnet:
```bash
clarinet integrate
```

2. Deploy to testnet:
```bash
clarinet deployments apply --network testnet
```

### Mainnet Deployment

1. Update Mainnet.toml with production settings
2. Deploy to mainnet:
```bash
clarinet deployments apply --network mainnet
```

3. Initialize the contract:
```bash
stx call_contract_func <deployer-address> GrantAllocation initialize
```

## Security Considerations

### Access Control
- Contract owner has exclusive rights to add/remove administrators
- Only administrators can create grants, approve proposals, and distribute funds
- Researchers can only submit proposals and vote (one vote per proposal)

### Validation Mechanisms
- All funding amounts are validated against available grant budgets
- Double voting prevention through blockchain state verification
- Proposal submissions restricted to active grant periods
- Status checks prevent invalid state transitions

### Best Practices
- Regular auditing of administrator permissions
- Monitoring of unusual voting patterns
- Verification of researcher credentials before profile registration
- Implementation of additional token transfer mechanisms for fund distribution

## Error Codes

- `u100` - Owner only operation
- `u101` - Resource not found
- `u102` - Invalid amount specified
- `u103` - User already voted
- `u104` - Voting period closed
- `u105` - Insufficient funds available
- `u106` - Invalid status for operation
- `u107` - Unauthorized access

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with comprehensive tests
4. Submit pull request with detailed description

## License

This project is open source. Please refer to the license file for terms and conditions.

## Support

For technical support and questions:
- Review the contract documentation
- Check existing issues and discussions
- Submit detailed bug reports with reproduction steps