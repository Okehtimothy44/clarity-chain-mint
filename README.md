# ChainMint
A platform for tokenizing physical assets on the Stacks blockchain.

## Features
- Create new asset types/classes 
- Mint NFTs representing physical assets
- Transfer asset ownership
- Asset metadata storage and retrieval
- Asset verification and status tracking

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; Create a new asset class (admin only)
(contract-call? .chain-mint create-asset-class "Real Estate" "REAL")

;; Mint a new asset token
(contract-call? .chain-mint mint-asset 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  "123 Main St" 
  {location: "Miami, FL", 
   size: "2000sqft",
   verified: true})

;; Transfer asset ownership
(contract-call? .chain-mint transfer-asset u1
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Get asset details
(contract-call? .chain-mint get-asset-details u1)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
