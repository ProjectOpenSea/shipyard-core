// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTNumericTraitsDynamic} from "script/metadata-test/numeric-traits/TestNFTNumericTraitsDynamic.sol";
import {json} from "src/onchain/json.sol";
import {Metadata} from "src/onchain/Metadata.sol";
import {Solarray} from "solarray/Solarray.sol";

/**
 * @title DeployNumericTraitsDynamic
 * @notice Deploys TestNFTNumericTraitsDynamic with both static and dynamic numeric traits.
 *
 * Usage:
 *   # Deploy and mint 10 tokens to deployer
 *   forge script script/metadata-test/DeployNumericTraitsDynamic.s.sol --rpc-url <RPC> --broadcast --private-key <PK>
 *
 *   # Deploy and mint custom amount to custom address
 *   forge script script/metadata-test/DeployNumericTraitsDynamic.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK> \
 *     --sig "deploy(address,uint256)" <RECIPIENT> <AMOUNT>
 *
 * Static Traits (tokenURI):
 *   - Power: 1-9 (single digit)
 *   - Speed: 10-99 (double digit)
 *
 * Dynamic Traits (ERC-7496):
 *   - Boost: 1-9 (single digit)
 *   - Score: 100-999 (triple digit)
 *   - Reputation: 10000-999999 (5-6 digits)
 */
contract DeployNumericTraitsDynamic is Script {
    uint256 constant DEFAULT_AMOUNT = 10;

    // Dynamic trait keys
    bytes32 constant BOOST_KEY = keccak256("Boost");
    bytes32 constant SCORE_KEY = keccak256("Score");
    bytes32 constant REPUTATION_KEY = keccak256("Reputation");

    function run() public {
        deploy(msg.sender, DEFAULT_AMOUNT);
    }

    function deploy(address recipient, uint256 amount) public {
        vm.startBroadcast();

        // Deploy the contract
        TestNFTNumericTraitsDynamic nft = new TestNFTNumericTraitsDynamic();
        console2.log("Deployed TestNFTNumericTraitsDynamic at:", address(nft));

        // Build on-chain trait metadata JSON and register trait keys
        string memory traitMetadataJson = _buildTraitMetadataJson();
        string memory traitMetadataURI = Metadata.base64JsonDataURI(traitMetadataJson);
        bytes32[] memory traitKeys = new bytes32[](3);
        traitKeys[0] = BOOST_KEY;
        traitKeys[1] = SCORE_KEY;
        traitKeys[2] = REPUTATION_KEY;
        nft.setTraitMetadataURI(traitMetadataURI, traitKeys);
        console2.log("Set trait metadata URI and registered dynamic trait keys");

        // Bulk mint tokens
        (uint256 startId, uint256 endId) = nft.bulkMint(recipient, amount);
        console2.log("Minted tokens to:", recipient);
        console2.log("Start ID:", startId);
        console2.log("End ID:", endId);

        // Set dynamic traits for all tokens using efficient batch function
        console2.log("Setting dynamic traits for all tokens (batch)...");
        nft.batchSetTraitsForRange(
            startId,
            endId,
            BOOST_KEY,
            SCORE_KEY,
            REPUTATION_KEY,
            "boost",
            "score",
            "reputation"
        );
        console2.log("Dynamic traits set for all tokens");

        vm.stopBroadcast();

        // Log summary
        _logSummary(nft, amount, recipient);
    }

    // ============ Deterministic dynamic trait values ============

    function _getBoost(uint256 tokenId) internal pure returns (uint256) {
        // Range: 1-9
        return (uint256(keccak256(abi.encodePacked("boost", tokenId))) % 9) + 1;
    }

    function _getScore(uint256 tokenId) internal pure returns (uint256) {
        // Range: 100-999
        return (uint256(keccak256(abi.encodePacked("score", tokenId))) % 900) + 100;
    }

    function _getReputation(uint256 tokenId) internal pure returns (uint256) {
        // Range: 10000-999999
        return (uint256(keccak256(abi.encodePacked("reputation", tokenId))) % 990000) + 10000;
    }

    // ============ Trait metadata builder ============

    function _buildTraitMetadataJson() internal pure returns (string memory) {
        // Boost trait - unsigned integer (1-9)
        string memory boostTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Boost"),
                json.rawProperty(
                    "dataType",
                    json.objectOf(
                        Solarray.strings(
                            json.property("type", "decimal"),
                            json.rawProperty("signed", "false"),
                            json.rawProperty("bits", "8"),
                            json.rawProperty("decimals", "0")
                        )
                    )
                ),
                json.property("validateOnSale", "requireUintGte")
            )
        );

        // Score trait - unsigned integer (100-999)
        string memory scoreTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Score"),
                json.rawProperty(
                    "dataType",
                    json.objectOf(
                        Solarray.strings(
                            json.property("type", "decimal"),
                            json.rawProperty("signed", "false"),
                            json.rawProperty("bits", "16"),
                            json.rawProperty("decimals", "0")
                        )
                    )
                ),
                json.property("validateOnSale", "requireUintGte")
            )
        );

        // Reputation trait - unsigned integer (10000-999999)
        string memory reputationTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Reputation"),
                json.rawProperty(
                    "dataType",
                    json.objectOf(
                        Solarray.strings(
                            json.property("type", "decimal"),
                            json.rawProperty("signed", "false"),
                            json.rawProperty("bits", "32"),
                            json.rawProperty("decimals", "0")
                        )
                    )
                ),
                json.property("validateOnSale", "requireUintGte")
            )
        );

        // Combine all traits into the root object
        string memory traits = json.objectOf(
            Solarray.strings(
                json.rawProperty("Boost", boostTrait),
                json.rawProperty("Score", scoreTrait),
                json.rawProperty("Reputation", reputationTrait)
            )
        );

        return json.objectOf(Solarray.strings(json.rawProperty("traits", traits)));
    }

    // ============ Logging ============

    function _logSummary(TestNFTNumericTraitsDynamic nft, uint256 amount, address recipient) internal pure {
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("Contract: TestNFTNumericTraitsDynamic");
        console2.log("Address:", address(nft));
        console2.log("Tokens minted:", amount);
        console2.log("Recipient:", recipient);
        console2.log("");
        console2.log("=== Static Traits (tokenURI) ===");
        console2.log("Power: 1-9 (single digit)");
        console2.log("Speed: 10-99 (double digit)");
        console2.log("");
        console2.log("=== Dynamic Traits (ERC-7496) ===");
        console2.log("Boost: 1-9 (single digit)");
        console2.log("Score: 100-999 (triple digit)");
        console2.log("Reputation: 10000-999999 (5-6 digits)");
        console2.log("");

        // Show sample distribution
        console2.log("=== Sample Distribution ===");
        console2.log("Token | Power | Speed | Boost | Score | Reputation");
        console2.log("------|-------|-------|-------|-------|------------");

        uint256[] memory samples = new uint256[](5);
        samples[0] = 1;
        samples[1] = 100;
        samples[2] = 500;
        samples[3] = 750;
        samples[4] = 1000;

        for (uint256 i = 0; i < samples.length; i++) {
            uint256 tokenId = samples[i];
            console2.log(
                string.concat(
                    _padLeft(tokenId, 5),
                    " | ",
                    _padLeft(nft.getPower(tokenId), 5),
                    " | ",
                    _padLeft(nft.getSpeed(tokenId), 5),
                    " | ",
                    _padLeft(_getBoost(tokenId), 5),
                    " | ",
                    _padLeft(_getScore(tokenId), 5),
                    " | ",
                    _padLeft(_getReputation(tokenId), 10)
                )
            );
        }
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
