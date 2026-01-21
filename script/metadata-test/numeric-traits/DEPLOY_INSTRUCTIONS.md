# Numeric Traits Test Scripts (for OpenSea Trait Offers)

These scripts deploy NFT contracts with number-based traits (like "Power: 5" or "Score: 847") so we can test OpenSea's trait offer feature, which lets buyers make offers like "I'll buy any NFT with Power > 5" or "Score <= 500".

## Setup & Deploy

**1. Install Foundry** (if you don't have it):
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**2. Clone and checkout the branch:**
```bash
git clone git@github.com:ProjectOpenSea/shipyard-core.git
cd shipyard-core
git checkout test-dynamic-traits-deployments
```

**3. Set your environment variables:**
```bash
export RPC=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY
export PK=0xYourPrivateKeyHere
```

**4. Deploy:**
```bash
forge script script/metadata-test/numeric-traits/DeployNumericTraitsDynamic.s.sol --rpc-url $RPC --broadcast --private-key $PK
```

This deploys a contract and mints 10 NFTs to your wallet. Each NFT has 5 numeric traits with different value ranges (single digit, double digit, triple digit, etc.) so you can test all the comparison operators (`>`, `>=`, `<`, `<=`, `=`) on OpenSea.

## Trait Ranges

| Source | Trait | Range | Example Values |
|--------|-------|-------|----------------|
| Static (tokenURI) | Power | 1-9 | 3, 5, 8 |
| Static (tokenURI) | Speed | 10-99 | 15, 44, 75 |
| Dynamic (ERC-7496) | Boost | 1-9 | 2, 5, 8 |
| Dynamic (ERC-7496) | Score | 100-999 | 223, 641, 676 |
| Dynamic (ERC-7496) | Reputation | 10,000-999,999 | 14045, 245183, 314932 |

## Sample Token Distribution

| Token | Power | Speed | Boost | Score | Reputation |
|-------|-------|-------|-------|-------|------------|
| 1 | 5 | 70 | 2 | 223 | 245183 |
| 2 | 4 | 28 | 6 | 512 | 87234 |
| 3 | 7 | 91 | 4 | 847 | 156789 |
| 4 | 2 | 45 | 9 | 301 | 423567 |
| 5 | 8 | 63 | 1 | 678 | 892341 |
