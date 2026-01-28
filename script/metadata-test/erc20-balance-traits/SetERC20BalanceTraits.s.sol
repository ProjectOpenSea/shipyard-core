// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTERC20BalanceTraits} from "script/metadata-test/erc20-balance-traits/TestNFTERC20BalanceTraits.sol";

/**
 * @title SetERC20BalanceTraits
 * @notice Helper script to set/update balance traits on an existing TestNFTERC20BalanceTraits deployment.
 *
 * Usage:
 *   # Set balance for a single token
 *   forge script script/metadata-test/erc20-balance-traits/SetERC20BalanceTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK> \
 *     --sig "setBalance(address,uint256,uint256)" <CONTRACT> <TOKEN_ID> <BALANCE_WEI>
 *
 *   # Set balance using token units (will multiply by 1e18)
 *   forge script script/metadata-test/erc20-balance-traits/SetERC20BalanceTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK> \
 *     --sig "setBalanceTokens(address,uint256,uint256)" <CONTRACT> <TOKEN_ID> <TOKENS>
 *
 *   # Batch set balances for multiple tokens
 *   forge script script/metadata-test/erc20-balance-traits/SetERC20BalanceTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK> \
 *     --sig "batchSetBalances(address,uint256[],uint256[])" <CONTRACT> "[1,2,3]" "[1e18,2e18,3e18]"
 */
contract SetERC20BalanceTraits is Script {
    bytes32 constant BALANCE_KEY = keccak256("balance");
    uint256 constant ONE_TOKEN = 1e18;

    /// @notice Set balance for a single token (value in wei)
    function setBalance(address contractAddr, uint256 tokenId, uint256 balanceWei) public {
        vm.startBroadcast();

        TestNFTERC20BalanceTraits nft = TestNFTERC20BalanceTraits(contractAddr);
        
        // Use setTraitIfChanged to avoid revert if unchanged
        nft.setTraitIfChanged(tokenId, BALANCE_KEY, bytes32(balanceWei));
        
        console2.log("Set balance for token", tokenId);
        console2.log("Balance (wei):", balanceWei);
        console2.log("Balance (tokens):", balanceWei / ONE_TOKEN);

        vm.stopBroadcast();
    }

    /// @notice Set balance for a single token (value in whole tokens, will multiply by 1e18)
    function setBalanceTokens(address contractAddr, uint256 tokenId, uint256 tokens) public {
        setBalance(contractAddr, tokenId, tokens * ONE_TOKEN);
    }

    /// @notice Set balance with fractional tokens (whole + fraction in wei)
    /// @param wholeTokens Number of whole tokens
    /// @param fractionWei Fractional part in wei (0 to 999999999999999999)
    function setBalanceMixed(address contractAddr, uint256 tokenId, uint256 wholeTokens, uint256 fractionWei) public {
        require(fractionWei < ONE_TOKEN, "Fraction must be less than 1e18");
        uint256 totalWei = wholeTokens * ONE_TOKEN + fractionWei;
        setBalance(contractAddr, tokenId, totalWei);
    }

    /// @notice Batch set balances for multiple tokens
    function batchSetBalances(address contractAddr, uint256[] calldata tokenIds, uint256[] calldata balancesWei) public {
        require(tokenIds.length == balancesWei.length, "Length mismatch");
        
        vm.startBroadcast();

        TestNFTERC20BalanceTraits nft = TestNFTERC20BalanceTraits(contractAddr);
        
        bytes32[] memory values = new bytes32[](balancesWei.length);
        for (uint256 i = 0; i < balancesWei.length; i++) {
            values[i] = bytes32(balancesWei[i]);
        }
        
        nft.batchSetTrait(tokenIds, BALANCE_KEY, values);
        
        console2.log("Batch set balances for", tokenIds.length, "tokens");

        vm.stopBroadcast();
    }

    /// @notice Read and display current balance for a token
    function getBalance(address contractAddr, uint256 tokenId) public view {
        TestNFTERC20BalanceTraits nft = TestNFTERC20BalanceTraits(contractAddr);
        uint256 balanceWei = uint256(nft.getTraitValue(tokenId, BALANCE_KEY));
        
        console2.log("Token ID:", tokenId);
        console2.log("Balance (wei):", balanceWei);
        console2.log("Balance (tokens):", balanceWei / ONE_TOKEN);
        console2.log("Fractional (wei):", balanceWei % ONE_TOKEN);
    }
}
