// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTERC20BalanceTraits} from "script/metadata-test/erc20-balance-traits/TestNFTERC20BalanceTraits.sol";
import {json} from "src/onchain/json.sol";
import {Metadata} from "src/onchain/Metadata.sol";
import {Solarray} from "solarray/Solarray.sol";

/**
 * @title DeployERC20BalanceTraits
 * @notice Deploys TestNFTERC20BalanceTraits with sample tokens demonstrating various
 *         ERC20-style balance values with 18 decimals.
 *
 * Usage:
 *   forge script script/metadata-test/erc20-balance-traits/DeployERC20BalanceTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK>
 *
 * Test Scenarios (20 tokens total):
 *   Token 1:  Zero balance (default, no trait set)
 *   Token 2:  1 wei (smallest possible: 0.000000000000000001)
 *   Token 3:  999 wei (0.000000000000000999)
 *   Token 4:  0.000000000000001 (1000 wei / 1e3)
 *   Token 5:  0.000000000001 (1e6 wei)
 *   Token 6:  0.000001 (1e12 wei)
 *   Token 7:  0.01 tokens (1e16 wei)
 *   Token 8:  0.1 tokens (1e17 wei)
 *   Token 9:  0.5 tokens (5e17 wei)
 *   Token 10: 0.123456789012345678 (all 18 decimals)
 *   Token 11: 0.999999999999999999 (just under 1)
 *   Token 12: 1 token exactly (1e18)
 *   Token 13: 1.000000000000000001 (1 token + 1 wei)
 *   Token 14: 10 tokens (1e19)
 *   Token 15: 100.5 tokens (mixed whole + simple fraction)
 *   Token 16: 1,000 tokens (1e21)
 *   Token 17: 123,456.789012345678901234 (large with full precision, truncated to 18 decimals)
 *   Token 18: 1,000,000 tokens (1e24 - million)
 *   Token 19: 10,000,000,000 tokens (1e28 - 10 BILLION total supply)
 *   Token 20: 10B + fractional (10,000,000,000.123456789012345678)
 */
contract DeployERC20BalanceTraits is Script {
    // Trait key
    bytes32 constant BALANCE_KEY = keccak256("balance");

    // ERC20 decimal constants
    uint256 constant DECIMALS = 18;
    uint256 constant ONE_TOKEN = 10 ** DECIMALS; // 1e18

    function run() public {
        vm.startBroadcast();

        // Deploy the contract
        TestNFTERC20BalanceTraits nft = new TestNFTERC20BalanceTraits();
        console2.log("Deployed TestNFTERC20BalanceTraits at:", address(nft));

        // Build on-chain trait metadata JSON and register trait key
        string memory traitMetadataJson = _buildTraitMetadataJson();
        string memory traitMetadataURI = Metadata.base64JsonDataURI(traitMetadataJson);
        bytes32[] memory traitKeys = new bytes32[](1);
        traitKeys[0] = BALANCE_KEY;
        nft.setTraitMetadataURI(traitMetadataURI, traitKeys);
        console2.log("Set trait metadata URI and registered balance trait key");

        // Mint 20 tokens to the deployer
        address deployer = msg.sender;
        (uint256 startId, uint256 endId) = nft.bulkMint(deployer, 20);
        console2.log("Minted tokens", startId, "to", endId);
        console2.log("Recipient:", deployer);

        // Set balance traits for each token with different test scenarios
        _setBalanceTraits(nft);

        console2.log("Set balance traits for all tokens");

        vm.stopBroadcast();

        // Log summary
        _logSummary(nft);
    }

    function _setBalanceTraits(TestNFTERC20BalanceTraits nft) internal {
        // Token 1: Zero balance - skip (default is 0)
        // No setTrait call needed

        // Token 2: 1 wei (smallest possible: 0.000000000000000001)
        nft.setTrait(2, BALANCE_KEY, bytes32(uint256(1)));

        // Token 3: 999 wei (0.000000000000000999)
        nft.setTrait(3, BALANCE_KEY, bytes32(uint256(999)));

        // Token 4: 0.000000000000001 (1000 wei / 1e3)
        nft.setTrait(4, BALANCE_KEY, bytes32(uint256(1e3)));

        // Token 5: 0.000000000001 (1e6 wei)
        nft.setTrait(5, BALANCE_KEY, bytes32(uint256(1e6)));

        // Token 6: 0.000001 (1e12 wei)
        nft.setTrait(6, BALANCE_KEY, bytes32(uint256(1e12)));

        // Token 7: 0.01 tokens (1e16 wei)
        nft.setTrait(7, BALANCE_KEY, bytes32(uint256(1e16)));

        // Token 8: 0.1 tokens (1e17 wei)
        nft.setTrait(8, BALANCE_KEY, bytes32(uint256(1e17)));

        // Token 9: 0.5 tokens (5e17 wei)
        nft.setTrait(9, BALANCE_KEY, bytes32(uint256(5e17)));

        // Token 10: 0.123456789012345678 (all 18 decimals used)
        nft.setTrait(10, BALANCE_KEY, bytes32(uint256(123456789012345678)));

        // Token 11: 0.999999999999999999 (just under 1 token)
        nft.setTrait(11, BALANCE_KEY, bytes32(uint256(999999999999999999)));

        // Token 12: 1 token exactly (1e18)
        nft.setTrait(12, BALANCE_KEY, bytes32(uint256(ONE_TOKEN)));

        // Token 13: 1.000000000000000001 (1 token + 1 wei)
        nft.setTrait(13, BALANCE_KEY, bytes32(uint256(ONE_TOKEN + 1)));

        // Token 14: 10 tokens (1e19)
        nft.setTrait(14, BALANCE_KEY, bytes32(uint256(10 * ONE_TOKEN)));

        // Token 15: 100.5 tokens (mixed whole + simple fraction)
        nft.setTrait(15, BALANCE_KEY, bytes32(uint256(100 * ONE_TOKEN + 5e17)));

        // Token 16: 1,000 tokens (1e21)
        nft.setTrait(16, BALANCE_KEY, bytes32(uint256(1000 * ONE_TOKEN)));

        // Token 17: 123,456.789012345678 (large with full 18 decimal precision)
        // 123456 * 1e18 + 789012345678000000 = 123456789012345678000000
        nft.setTrait(17, BALANCE_KEY, bytes32(uint256(123456 * ONE_TOKEN + 789012345678000000)));

        // Token 18: 1,000,000 tokens (1e24 - million)
        nft.setTrait(18, BALANCE_KEY, bytes32(uint256(1_000_000 * ONE_TOKEN)));

        // Token 19: 10,000,000,000 tokens (1e28 - 10 BILLION total supply)
        // This is a common ERC20 total supply (10B tokens with 18 decimals)
        nft.setTrait(19, BALANCE_KEY, bytes32(uint256(10_000_000_000 * ONE_TOKEN)));

        // Token 20: 10B + fractional (10,000,000,000.123456789012345678)
        // Full 10B supply with maximum decimal precision
        nft.setTrait(20, BALANCE_KEY, bytes32(uint256(10_000_000_000 * ONE_TOKEN + 123456789012345678)));
    }

    /// @dev Builds the ERC-7496 trait metadata JSON on-chain
    function _buildTraitMetadataJson() internal pure returns (string memory) {
        // Balance trait - unsigned integer with 18 decimals (ERC20 style)
        string memory balanceTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Token Balance"),
                json.rawProperty(
                    "dataType",
                    json.objectOf(
                        Solarray.strings(
                            json.property("type", "decimal"),
                            json.rawProperty("signed", "false"),
                            json.rawProperty("bits", "256"),
                            json.rawProperty("decimals", "18")
                        )
                    )
                ),
                json.property("validateOnSale", "requireUintGte")
            )
        );

        // Combine into the root object
        string memory traits = json.objectOf(
            Solarray.strings(
                json.rawProperty("balance", balanceTrait)
            )
        );

        return json.objectOf(Solarray.strings(json.rawProperty("traits", traits)));
    }

    function _logSummary(TestNFTERC20BalanceTraits nft) internal view {
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("Contract: TestNFTERC20BalanceTraits");
        console2.log("Address:", address(nft));
        console2.log("Tokens minted: 20");
        console2.log("Dynamic trait: balance (18 decimals)");
        console2.log("");
        console2.log("=== Test Scenarios ===");
        console2.log("Token | Category                  | Raw Value (wei)              | Display Value");
        console2.log("------|---------------------------|------------------------------|------------------------");
        
        _logToken(nft, 1,  "Zero balance",             0);
        _logToken(nft, 2,  "1 wei",                    1);
        _logToken(nft, 3,  "999 wei",                  999);
        _logToken(nft, 4,  "1e3 wei",                  1e3);
        _logToken(nft, 5,  "1e6 wei",                  1e6);
        _logToken(nft, 6,  "1e12 wei (0.000001)",      1e12);
        _logToken(nft, 7,  "0.01 tokens",              1e16);
        _logToken(nft, 8,  "0.1 tokens",               1e17);
        _logToken(nft, 9,  "0.5 tokens",               5e17);
        _logToken(nft, 10, "All 18 decimals",          123456789012345678);
        _logToken(nft, 11, "Just under 1",             999999999999999999);
        _logToken(nft, 12, "Exactly 1 token",          ONE_TOKEN);
        _logToken(nft, 13, "1 token + 1 wei",          ONE_TOKEN + 1);
        _logToken(nft, 14, "10 tokens",                10 * ONE_TOKEN);
        _logToken(nft, 15, "100.5 tokens",             100 * ONE_TOKEN + 5e17);
        _logToken(nft, 16, "1,000 tokens",             1000 * ONE_TOKEN);
        _logToken(nft, 17, "123,456.789... (18 dec)",  123456 * ONE_TOKEN + 789012345678000000);
        _logToken(nft, 18, "1 million tokens",         1_000_000 * ONE_TOKEN);
        _logToken(nft, 19, "10 BILLION (total supply)", 10_000_000_000 * ONE_TOKEN);
        _logToken(nft, 20, "10B + max decimals",       10_000_000_000 * ONE_TOKEN + 123456789012345678);
    }

    function _logToken(TestNFTERC20BalanceTraits nft, uint256 tokenId, string memory category, uint256 /* expectedValue */) internal view {
        uint256 actualValue = uint256(nft.getTraitValue(tokenId, BALANCE_KEY));
        string memory displayValue = _formatTokenAmount(actualValue);
        
        console2.log(
            string.concat(
                _padLeft(tokenId, 5),
                " | ",
                _padRight(category, 25),
                " | ",
                _padLeft(actualValue, 28),
                " | ",
                displayValue
            )
        );
    }

    /// @dev Formats a wei value as a human-readable token amount
    function _formatTokenAmount(uint256 weiValue) internal pure returns (string memory) {
        if (weiValue == 0) {
            return "0";
        }
        
        uint256 wholePart = weiValue / ONE_TOKEN;
        uint256 fractionalPart = weiValue % ONE_TOKEN;
        
        if (fractionalPart == 0) {
            return string.concat(_formatWithCommas(wholePart), " tokens");
        }
        
        // Format fractional part, trimming trailing zeros
        string memory fracStr = _formatFractional(fractionalPart);
        
        if (wholePart == 0) {
            return string.concat("0.", fracStr, " tokens");
        }
        
        return string.concat(_formatWithCommas(wholePart), ".", fracStr, " tokens");
    }

    function _formatFractional(uint256 fractional) internal pure returns (string memory) {
        // Pad to 18 digits
        bytes memory fracBytes = new bytes(18);
        uint256 temp = fractional;
        for (uint256 i = 18; i > 0; i--) {
            fracBytes[i - 1] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        
        // Find last non-zero digit
        uint256 lastNonZero = 18;
        for (uint256 i = 18; i > 0; i--) {
            if (fracBytes[i - 1] != bytes1("0")) {
                lastNonZero = i;
                break;
            }
        }
        
        // Trim trailing zeros
        bytes memory trimmed = new bytes(lastNonZero);
        for (uint256 i = 0; i < lastNonZero; i++) {
            trimmed[i] = fracBytes[i];
        }
        
        return string(trimmed);
    }

    function _formatWithCommas(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        string memory str = _toString(value);
        bytes memory strBytes = bytes(str);
        uint256 len = strBytes.length;
        
        if (len <= 3) return str;
        
        uint256 commaCount = (len - 1) / 3;
        bytes memory result = new bytes(len + commaCount);
        
        uint256 j = result.length;
        uint256 digitCount = 0;
        
        for (uint256 i = len; i > 0; i--) {
            if (digitCount > 0 && digitCount % 3 == 0) {
                j--;
                result[j] = ",";
            }
            j--;
            result[j] = strBytes[i - 1];
            digitCount++;
        }
        
        return string(result);
    }

    function _padLeft(uint256 value, uint256 width) internal pure returns (string memory) {
        bytes memory valueBytes = bytes(_toString(value));
        if (valueBytes.length >= width) {
            return string(valueBytes);
        }
        bytes memory result = new bytes(width);
        uint256 padding = width - valueBytes.length;
        for (uint256 i = 0; i < padding; i++) {
            result[i] = " ";
        }
        for (uint256 i = 0; i < valueBytes.length; i++) {
            result[padding + i] = valueBytes[i];
        }
        return string(result);
    }

    function _padRight(string memory str, uint256 width) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length >= width) {
            return str;
        }
        bytes memory result = new bytes(width);
        for (uint256 i = 0; i < strBytes.length; i++) {
            result[i] = strBytes[i];
        }
        for (uint256 i = strBytes.length; i < width; i++) {
            result[i] = " ";
        }
        return string(result);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
