# Metadata Pipeline Test Scripts

Test contracts and deployment scripts for verifying backend metadata pipeline handling of ERC-7496 dynamic traits and OpenSea trait offers.

## Directory Structure

```
metadata-test/
├── dynamic-traits/          # Pure ERC-7496 dynamic traits (no tokenURI traits)
├── numeric-traits/          # Numeric traits for OpenSea trait offer testing
├── conflicting/             # Dynamic traits that conflict with tokenURI traits
├── non-conflicting/         # Dynamic + tokenURI traits with no overlap
└── README.md
```

## Test Scenarios

| Folder | Contract | Dynamic Traits | tokenURI Traits | Purpose |
|--------|----------|----------------|-----------------|---------|
| `dynamic-traits/` | `TestNFTDynamicTraitsOnly` | Level, Experience, Guild, IsActive | None | Pure dynamic trait source |
| `numeric-traits/` | `TestNFTNumericTraits` | None | Power, Speed, Energy, Experience | OpenSea numeric trait offers (static only) |
| `numeric-traits/` | `TestNFTNumericTraitsDynamic` | Boost, Score, Reputation | Power, Speed | OpenSea numeric trait offers (static + dynamic) |
| `non-conflicting/` | `TestNFTNonConflicting` | Level, Experience, Guild | Background, Rarity, Generation | Merging from both sources |
| `conflicting/` | `TestNFTConflicting` | Level, Class, Guild | Level, Class, Background | Conflict resolution (dynamic wins) |

## Quick Start

```bash
# Dynamic traits only
forge script script/metadata-test/dynamic-traits/DeployDynamicTraitsOnly.s.sol \
  --rpc-url $RPC --broadcast --private-key $PK

# Numeric traits (static only) - for OpenSea trait offers
forge script script/metadata-test/numeric-traits/DeployNumericTraits.s.sol \
  --rpc-url $RPC --broadcast --private-key $PK

# Numeric traits (static + dynamic) - for OpenSea trait offers
forge script script/metadata-test/numeric-traits/DeployNumericTraitsDynamic.s.sol \
  --rpc-url $RPC --broadcast --private-key $PK

# Non-conflicting traits
forge script script/metadata-test/non-conflicting/DeployNonConflicting.s.sol \
  --rpc-url $RPC --broadcast --private-key $PK

# Conflicting traits
forge script script/metadata-test/conflicting/DeployConflicting.s.sol \
  --rpc-url $RPC --broadcast --private-key $PK
```

## Numeric Traits (for OpenSea Trait Offers)

Designed to test trait offer operators: `>` `>=` `<` `<=` `=`

### Static Only (`TestNFTNumericTraits`)
| Trait | Range | Digits |
|-------|-------|--------|
| Power | 1-9 | Single |
| Speed | 10-99 | Double |
| Energy | 100-999 | Triple |
| Experience | 10,000-999,999 | 5-6 |

### Static + Dynamic (`TestNFTNumericTraitsDynamic`)
| Source | Trait | Range | Digits |
|--------|-------|-------|--------|
| Static (tokenURI) | Power | 1-9 | Single |
| Static (tokenURI) | Speed | 10-99 | Double |
| Dynamic (ERC-7496) | Boost | 1-9 | Single |
| Dynamic (ERC-7496) | Score | 100-999 | Triple |
| Dynamic (ERC-7496) | Reputation | 10,000-999,999 | 5-6 |

## Utility Scripts

```bash
# Mint more tokens with traits on existing DynamicTraitsOnly contract
forge script script/metadata-test/dynamic-traits/MintDynamicTraitsOnly.s.sol \
  --rpc-url $RPC --broadcast --private-key $PK \
  --sig "run(address)" <CONTRACT_ADDRESS>

# Emit TraitMetadataURIUpdated to trigger backend refresh
forge script script/metadata-test/dynamic-traits/RefreshMetadataDynamicTraitsOnly.s.sol \
  --rpc-url $RPC --broadcast --private-key $PK \
  --sig "run(address)" <CONTRACT_ADDRESS>

# Emit various dynamic trait event types (TraitUpdated, TraitUpdatedRange, TraitUpdatedList, etc.)
# Useful for testing backend event indexing
forge script script/metadata-test/dynamic-traits/EmitDynamicTraitsTestEvents.s.sol \
  --rpc-url $RPC --broadcast --private-key $PK
```

## Notes

- Trait metadata is stored on-chain as base64 JSON data URIs
- Dynamic trait values are bytes32 encoded
- Uses Solady's `Ownable` and OpenZeppelin's ERC721
- Default deployment mints 10 tokens to deployer address
