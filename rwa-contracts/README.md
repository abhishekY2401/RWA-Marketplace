# Customizable RWA Token Framework

This framework provides a flexible and customizable solution for creating tokenized real-world assets (RWAs) with asset-specific compliance requirements.

## Overview

The key innovation in this framework is the ability to define custom compliance requirements for each real-world asset. This allows for different assets to have different regulatory and verification requirements based on:

- Asset type (real estate, art, commodities, etc.)
- Geographical restrictions
- Investor qualifications
- Regulatory compliance needs   

## Key Components

### 1. EnhancedComplianceRegistry

The `EnhancedComplianceRegistry` contract stores user verification data, including:
- Age verification (18+, 21+, 55+)
- Government ID verification
- Address verification
- Accredited investor status
- Tax residency verification
- AML/KYC check status
- Country of residence

This registry is managed by approved verifiers who can update user compliance status.

### 2. ComplianceManager

The `ComplianceManager` contract manages the compliance requirements for each asset, allowing:
- Setting different verification requirements per asset
- Managing country restrictions for each asset
- Checking if users meet the requirements for specific assets

### 3. CustomizableRWAToken

This ERC-20 token implementation represents a tokenized real-world asset with:
- Customizable compliance checks for transfers
- Standard ERC-20 functionality with compliance-aware transfers
- Metadata for the underlying asset

### 4. RWATokenFactory

A factory contract for creating new RWA tokens with specific compliance requirements.

## How It Works

1. Deploy the compliance system (Registry and Manager)
2. Define asset-specific compliance requirements
3. Create tokens for each real-world asset
4. Verify users according to regulatory requirements
5. Users can only transfer/receive tokens if they meet the asset's specific requirements

## Example Use Cases

### Real Estate Token (High Requirements)
- Requires accredited investor status
- Limited to certain countries
- Requires full KYC/AML verification
- Requires tax residency verification

### Art NFT Fractionalization (Medium Requirements)
- Available to non-accredited investors
- Age verification (21+)
- Basic KYC required
- Available in more countries

### Community Solar Project (Lower Requirements)
- Restricted by geography (local only)
- Basic verification
- No accreditation requirement

## Getting Started

Check the `test/CustomizableRWAExample.js` file for examples of how to:
- Deploy the contracts
- Set up verification for users
- Create tokens with different compliance requirements
- Check user eligibility for different assets

## Benefits

- Regulatory compliance per asset
- Flexibility to support various RWA types
- Future-proof design with extensible verification fields
- Gas-efficient compliance checking

## Security Considerations

In production:
- Use secure oracles for verification data
- Implement multi-signature controls for verifiers
- Consider privacy implications of on-chain verification data
- Audit thoroughly before deployment
