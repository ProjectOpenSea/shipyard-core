# Roadmap

-   [ ] Conduit pre-approvals
    -   [ ] ERC721
        -   [x] Solady
        -   [x] OpenZeppelin
        -   [ ] ERC721A
    -   [x] ERC1155
        -   [x] Solady
        -   [x] OpenZeppelin
-   [x] Onchain helpers
    -   [x] json
    -   [x] svg
-   [ ] Interfaces
    -   [ ] Redeemables?
        -   [ ] These are already defined in Redeemables repo
    -   [ ] SeaDrop?
        -   [ ] These are already defined in SeaDrop repo
    -   [ ] IERC4906?
        -   [ ] this is already defined in OpenZeppelin
    -   [x] Dynamic Metadata
    -   [x] Interface Delegation
    -   [x] PreapprovalForAll
    -   [ ] Queryable?
        -   [ ] maybe useful in tandem with interface delegation
    -   [x] SIPS 5, 6, 7, 10
-   [ ] Reference Implementations
    -   [x] IERC5912 Staking
    -   [ ] IERC4906 Metadata Updates
    -   [ ] IERCDynamicMetadata
    -   [ ] IERCInterfaceDelegation
    -   [x] AbstractSIP5
    -   [x] AbstractSIP6
    -   [x] AbstractSIP7
    -   [x] AbstractSIP10
-   [ ] SignedZone
    -   [ ] port from seaport repo

# Quick Start Guide

To deploy an NFT contract to the Goerli testnet, fund an address with 0.25 Goerli ETH, swap in the appropriate values for `<your_key>` and `<your_pk>` in this command, open a terminal window, and run the following:

```
git clone git@github.com:ProjectOpenSea/shipyard-core.git &&
cd shipyard-core &&
curl -L https://foundry.paradigm.xyz | bash &&
foundryup &&
forge build &&
export GOERLI_RPC='https://goerli.blockpi.network/v1/rpc/public &&
export ETHERSCAN_API_KEY='<your_key>' &&
export MY_ACTUAL_PK_BE_CAREFUL='<your_pk>' &&
forge create --rpc-url $GOERLI_RPC \
    --private-key $MY_ACTUAL_PK_BE_CAREFUL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --verify \
    src/reference/ExampleNFT.sol:ExampleNFT
```

A quick breakdown of each step follows.

Clone the `shipyard-core` repository and change directories into it:
```
git clone git@github.com:ProjectOpenSea/shipyard-core.git &&
cd shipyard-core
```

Install the `foundryup` up command and run it, which in turn installs forge, cast, anvil, and chisel:
```
curl -L https://foundry.paradigm.xyz | bash &&
foundryup
```

Install dependencies and compile the contracts:
```
forge build
```

Set up your environment variables:
```
export GOERLI_RPC='https://goerli.blockpi.network/v1/rpc/public	 &&
export ETHERSCAN_API_KEY='<your_key>' &&
export MY_ACTUAL_PK_BE_CAREFUL='<your_pk>'
```

Run the `forge create` command, which deploys the contract:
```
forge create --rpc-url $GOERLI_RPC \
    --private-key $MY_ACTUAL_PK_BE_CAREFUL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --verify \
    src/reference/ExampleNFT.sol:ExampleNFT
```

See https://book.getfoundry.sh/reference/forge/forge-create for more information on `forge create`.

## Deploying to mainnet

To deploy to mainnet, just replace the value supplied to `--rpc-url` with a mainnet RPC URL. For example:

```
export MAINNET_RPC='https://eth.llamarpc.com' &&
forge create --rpc-url $MAINNET_RPC \
    --private-key $MY_ACTUAL_PK_BE_CAREFUL \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --verify \
    src/reference/ExampleNFT.sol:ExampleNFT
```

Note that this will deploy ExampleNFT to mainnet, which will cost real money and will not produce much value as a result.

# Running ffi tests

Currently, the ffi tests are the only way to test the output of ExampleNFT's tokenURI response. More options soon™.

In general, it's wise to be especially wary of ffi code. In the words of the Foundrybook, "It is generally advised to use this cheat code as a last resort, and to not enable it by default, as anyone who can change the tests of a project will be able to execute arbitrary commands on devices that run the tests."

## Environment configuration

To run the ffi tests locally, set `FOUNDRY_PROFILE='ffi'` in your `.env` file, and then source the `.env` file. This will permit Forge to make foreign calls (`ffi = true`) and read and write within the `./test-ffi/` directory. It also tells Forge to run the tests in the `./test-ffi/` directory instead of the tests in the `./test/` directory, which are run by default. Check out the `foundry.toml` file, where all of this and more is configured.

Both the local profile and the CI profile for the ffi tests use a low number of fuzz runs, because the ffi lifecycle is slow. Before yeeting a project to mainnet, it's advisable to crank up the number of fuzz runs to increase the likelihood of catching an issue. It'll take more time, but it increases the likelihood of catching an issue.

## Expected local behavior

The `ExampleNFT.t.sol` file will call `ExampleNFT.sol`'s `tokenURI` function, decode the base64 encoded response, write the decoded version to `./test-ffi/tmp/temp.json`, and then call the `process_json.js` file a few times to get string values. If the expected values and the actual values match, the test will pass. A `temp.json` file will be left behind. You can ignore it or delete it; Forge makes a new one on the fly if it's not there. And it's ignored in the `.gitignore` file, so there's no need to worry about pushing cruft or top secret metadata to a shared/public repo.

## Expected CI behavior

When a PR is opened or when a new commit is pushed, Github runs a series of actions defined in the files in `.github/workflows/*.yml`. The normal Forge tests and linting are set up in `test.yml`. The ffi tests are set up in `test-ffi.yml`. Forks of this repository can safely disregard it or if it's not necessary, remove it entirely.