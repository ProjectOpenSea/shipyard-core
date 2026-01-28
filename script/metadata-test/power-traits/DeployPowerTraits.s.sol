// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTPowerTraits} from "script/metadata-test/power-traits/TestNFTPowerTraits.sol";
import {json} from "src/onchain/json.sol";
import {Metadata} from "src/onchain/Metadata.sol";
import {Solarray} from "solarray/Solarray.sol";

/**
 * @title DeployPowerTraits
 * @notice Deploys TestNFTPowerTraits with sample NFTs demonstrating various
 *         power level values with 18 decimal precision.
 *
 * Usage:
 *   forge script script/metadata-test/power-traits/DeployPowerTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK>
 *
 * Test Scenarios (20 NFTs total):
 *   NFT 1:  Zero power (default, no trait set)
 *   NFT 2:  1 unit (smallest possible: 0.000000000000000001)
 *   NFT 3:  999 units (0.000000000000000999)
 *   NFT 4:  0.000000000000001 (1000 units / 1e3)
 *   NFT 5:  0.000000000001 (1e6 units)
 *   NFT 6:  0.000001 (1e12 units)
 *   NFT 7:  0.01 power (1e16 units)
 *   NFT 8:  0.1 power (1e17 units)
 *   NFT 9:  0.5 power (5e17 units)
 *   NFT 10: 0.123456789012345678 (all 18 decimals)
 *   NFT 11: 0.999999999999999999 (just under 1)
 *   NFT 12: 1 power exactly (1e18)
 *   NFT 13: 1.000000000000000001 (1 power + 1 unit)
 *   NFT 14: 10 power (1e19)
 *   NFT 15: 100.5 power (mixed whole + simple fraction)
 *   NFT 16: 1,000 power (1e21)
 *   NFT 17: 123,456.789012345678901234 (large with full precision, truncated to 18 decimals)
 *   NFT 18: 1,000,000 power (1e24 - million)
 *   NFT 19: 10,000,000,000 power (1e28 - 10 BILLION)
 *   NFT 20: 10B + fractional (10,000,000,000.123456789012345678)
 */
contract DeployPowerTraits is Script {
    // Trait key
    bytes32 constant POWER_KEY = keccak256("power");

    // Decimal constants
    uint256 constant DECIMALS = 18;
    uint256 constant ONE_UNIT = 10 ** DECIMALS; // 1e18

    function run() public {
        vm.startBroadcast();

        // Deploy the contract
        TestNFTPowerTraits nft = new TestNFTPowerTraits();
        console2.log("Deployed TestNFTPowerTraits at:", address(nft));

        // Build on-chain trait metadata JSON and register trait key
        string memory traitMetadataJson = _buildTraitMetadataJson();
        string memory traitMetadataURI = Metadata.base64JsonDataURI(traitMetadataJson);
        bytes32[] memory traitKeys = new bytes32[](1);
        traitKeys[0] = POWER_KEY;
        nft.setTraitMetadataURI(traitMetadataURI, traitKeys);
        console2.log("Set trait metadata URI and registered power trait key");

        // Mint 20 NFTs to the deployer
        address deployer = msg.sender;
        (uint256 startId, uint256 endId) = nft.bulkMint(deployer, 20);
        console2.log("Minted NFTs", startId, "to", endId);
        console2.log("Recipient:", deployer);

        // Set power levels for each NFT with different test scenarios
        _setPowerTraits(nft);

        console2.log("Set power levels for all NFTs");

        vm.stopBroadcast();

        // Log summary
        _logSummary(nft);
    }

    function _setPowerTraits(TestNFTPowerTraits nft) internal {
        // NFT 1: Zero power - skip (default is 0)
        // No setTrait call needed

        // NFT 2: 1 unit (smallest possible: 0.000000000000000001)
        nft.setTrait(2, POWER_KEY, bytes32(uint256(1)));

        // NFT 3: 999 units (0.000000000000000999)
        nft.setTrait(3, POWER_KEY, bytes32(uint256(999)));

        // NFT 4: 0.000000000000001 (1000 units / 1e3)
        nft.setTrait(4, POWER_KEY, bytes32(uint256(1e3)));

        // NFT 5: 0.000000000001 (1e6 units)
        nft.setTrait(5, POWER_KEY, bytes32(uint256(1e6)));

        // NFT 6: 0.000001 (1e12 units)
        nft.setTrait(6, POWER_KEY, bytes32(uint256(1e12)));

        // NFT 7: 0.01 power (1e16 units)
        nft.setTrait(7, POWER_KEY, bytes32(uint256(1e16)));

        // NFT 8: 0.1 power (1e17 units)
        nft.setTrait(8, POWER_KEY, bytes32(uint256(1e17)));

        // NFT 9: 0.5 power (5e17 units)
        nft.setTrait(9, POWER_KEY, bytes32(uint256(5e17)));

        // NFT 10: 0.123456789012345678 (all 18 decimals used)
        nft.setTrait(10, POWER_KEY, bytes32(uint256(123456789012345678)));

        // NFT 11: 0.999999999999999999 (just under 1 power)
        nft.setTrait(11, POWER_KEY, bytes32(uint256(999999999999999999)));

        // NFT 12: 1 power exactly (1e18)
        nft.setTrait(12, POWER_KEY, bytes32(uint256(ONE_UNIT)));

        // NFT 13: 1.000000000000000001 (1 power + 1 unit)
        nft.setTrait(13, POWER_KEY, bytes32(uint256(ONE_UNIT + 1)));

        // NFT 14: 10 power (1e19)
        nft.setTrait(14, POWER_KEY, bytes32(uint256(10 * ONE_UNIT)));

        // NFT 15: 100.5 power (mixed whole + simple fraction)
        nft.setTrait(15, POWER_KEY, bytes32(uint256(100 * ONE_UNIT + 5e17)));

        // NFT 16: 1,000 power (1e21)
        nft.setTrait(16, POWER_KEY, bytes32(uint256(1000 * ONE_UNIT)));

        // NFT 17: 123,456.789012345678 (large with full 18 decimal precision)
        nft.setTrait(17, POWER_KEY, bytes32(uint256(123456 * ONE_UNIT + 789012345678000000)));

        // NFT 18: 1,000,000 power (1e24 - million)
        nft.setTrait(18, POWER_KEY, bytes32(uint256(1_000_000 * ONE_UNIT)));

        // NFT 19: 10,000,000,000 power (1e28 - 10 BILLION)
        nft.setTrait(19, POWER_KEY, bytes32(uint256(10_000_000_000 * ONE_UNIT)));

        // NFT 20: 10B + fractional (10,000,000,000.123456789012345678)
        // Maximum power with full decimal precision
        nft.setTrait(20, POWER_KEY, bytes32(uint256(10_000_000_000 * ONE_UNIT + 123456789012345678)));
    }

    /// @dev Builds the ERC-7496 trait metadata JSON on-chain
    function _buildTraitMetadataJson() internal pure returns (string memory) {
        // Power level trait - unsigned integer with 18 decimals for precision
        string memory powerTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Power Level"),
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
                json.rawProperty("power", powerTrait)
            )
        );

        return json.objectOf(Solarray.strings(json.rawProperty("traits", traits)));
    }

    function _logSummary(TestNFTPowerTraits nft) internal view {
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("Contract: TestNFTPowerTraits");
        console2.log("Address:", address(nft));
        console2.log("NFTs minted: 20");
        console2.log("Dynamic trait: power (18 decimals)");
        console2.log("");
        console2.log("=== Test Scenarios ===");
        console2.log("NFT   | Category                  | Raw Value (units)            | Display Value");
        console2.log("------|---------------------------|------------------------------|------------------------");

        _logNFT(nft, 1,  "Zero power",               0);
        _logNFT(nft, 2,  "1 unit",                   1);
        _logNFT(nft, 3,  "999 units",                999);
        _logNFT(nft, 4,  "1e3 units",                1e3);
        _logNFT(nft, 5,  "1e6 units",                1e6);
        _logNFT(nft, 6,  "1e12 units (0.000001)",    1e12);
        _logNFT(nft, 7,  "0.01 power",               1e16);
        _logNFT(nft, 8,  "0.1 power",                1e17);
        _logNFT(nft, 9,  "0.5 power",                5e17);
        _logNFT(nft, 10, "All 18 decimals",          123456789012345678);
        _logNFT(nft, 11, "Just under 1",             999999999999999999);
        _logNFT(nft, 12, "Exactly 1 power",          ONE_UNIT);
        _logNFT(nft, 13, "1 power + 1 unit",         ONE_UNIT + 1);
        _logNFT(nft, 14, "10 power",                 10 * ONE_UNIT);
        _logNFT(nft, 15, "100.5 power",              100 * ONE_UNIT + 5e17);
        _logNFT(nft, 16, "1,000 power",              1000 * ONE_UNIT);
        _logNFT(nft, 17, "123,456.789... (18 dec)",  123456 * ONE_UNIT + 789012345678000000);
        _logNFT(nft, 18, "1 million power",          1_000_000 * ONE_UNIT);
        _logNFT(nft, 19, "10 BILLION power",         10_000_000_000 * ONE_UNIT);
        _logNFT(nft, 20, "10B + max decimals",       10_000_000_000 * ONE_UNIT + 123456789012345678);
    }

    function _logNFT(TestNFTPowerTraits nft, uint256 tokenId, string memory category, uint256 /* expectedValue */) internal view {
        uint256 actualValue = uint256(nft.getTraitValue(tokenId, POWER_KEY));
        string memory displayValue = _formatPowerAmount(actualValue);

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

    /// @dev Formats a raw value as a human-readable power level
    function _formatPowerAmount(uint256 rawValue) internal pure returns (string memory) {
        if (rawValue == 0) {
            return "0";
        }

        uint256 wholePart = rawValue / ONE_UNIT;
        uint256 fractionalPart = rawValue % ONE_UNIT;

        if (fractionalPart == 0) {
            return string.concat(_formatWithCommas(wholePart), " power");
        }

        // Format fractional part, trimming trailing zeros
        string memory fracStr = _formatFractional(fractionalPart);

        if (wholePart == 0) {
            return string.concat("0.", fracStr, " power");
        }

        return string.concat(_formatWithCommas(wholePart), ".", fracStr, " power");
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
