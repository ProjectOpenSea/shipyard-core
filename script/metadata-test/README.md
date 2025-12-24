# Metadata Pipeline Test Scripts

Test contracts and deployment scripts for verifying backend metadata pipeline handling of ERC-7496 dynamic traits.

## Test Scenarios

| Scenario | Contract | Dynamic Traits | tokenURI Traits | Purpose |
|----------|----------|----------------|-----------------|---------|
| **Dynamic Only** | `TestNFTDynamicTraitsOnly` | Level, Experience, Guild, IsActive | None | Pure dynamic trait source |
| **Non-Conflicting** | `TestNFTNonConflicting` | Level, Experience, Guild | Background, Rarity, Generation | Merging from both sources |
| **Conflicting** | `TestNFTConflicting` | Level, Class, Guild | Level, Class, Background | Conflict resolution (dynamic wins) |

## Quick Start

```bash
# Deploy (simulation first, then broadcast)
forge script script/metadata-test/DeployDynamicTraitsOnly.s.sol --rpc-url $RPC

# Deploy for real
forge script script/metadata-test/DeployDynamicTraitsOnly.s.sol --rpc-url $RPC --broadcast

# With verification
forge script script/metadata-test/DeployDynamicTraitsOnly.s.sol \
  --rpc-url $RPC --broadcast --verify --etherscan-api-key $API_KEY
```

## Scripts

### Deployment Scripts

Each deploys a test contract, mints 5 tokens (IDs 1-5), and sets dynamic traits:

- `DeployDynamicTraitsOnly.s.sol`
- `DeployNonConflicting.s.sol`
- `DeployConflicting.s.sol`

### Utility Scripts

```bash
# Mint 5 more tokens with traits on existing contract
forge script MintDynamicTraitsOnly \
  --rpc-url $RPC --broadcast \
  --sig "run(address)" <CONTRACT_ADDRESS>

# Emit TraitMetadataURIUpdated to trigger backend refresh
forge script RefreshMetadataDynamicTraitsOnly \
  --rpc-url $RPC --broadcast \
  --sig "run(address)" <CONTRACT_ADDRESS>
```

## Token Distribution

Each deployment mints 5 tokens with progressive trait values:

| Token | Level | Experience | Guild |
|-------|-------|------------|-------|
| 1 | 1 | 0 | None |
| 2 | 5 | 100 | Warriors |
| 3 | 10 | 500 | Mages |
| 4 | 25 | 2500 | Rogues |
| 5 | 50 | 10000 | Legends |

## Verification

### Dynamic Traits Only
- `getTraitValue(tokenId, "Level")` returns correct bytes32 value
- `getTraitMetadataURI()` returns base64-encoded JSON data URI
- `tokenURI(tokenId)` returns standard ERC721 metadata (no dynamic attributes)

### Non-Conflicting
- `tokenURI` includes Background, Rarity, Generation
- `getTraitValue` returns Level, Experience, Guild
- Backend merged metadata shows all 6 traits

### Conflicting
- `tokenURI` shows stale Level=1, Class="Peasant"
- `getTraitValue` shows correct dynamic Level (1-50) and Class
- Backend merged metadata uses dynamic values, not tokenURI values

## Notes

- Trait metadata is stored on-chain as base64 JSON data URIs
- Dynamic trait values are bytes32 encoded
- Uses Solady's `Ownable` and OpenZeppelin's ERC721
