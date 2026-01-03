// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTConflicting} from "./TestNFTConflicting.sol";
import {json} from "src/onchain/json.sol";
import {Metadata} from "src/onchain/Metadata.sol";
import {Solarray} from "solarray/Solarray.sol";

/**
 * @title DeployConflicting
 * @notice Deploys TestNFTConflicting with sample tokens that have both
 *         tokenURI metadata AND dynamic traits with OVERLAPPING/CONFLICTING keys.
 *
 * Usage:
 *   forge script script/metadata-test/DeployConflicting.s.sol --rpc-url <RPC> --broadcast
 *
 * tokenURI Traits (static, from tokenURI JSON):
 *   - "Level": 1, 1, 1, 1, 1 (CONFLICTING - same value for all in tokenURI)
 *   - "Class": "Peasant" for all (CONFLICTING - base class in tokenURI)
 *   - "Background": "Blue", "Red", "Green", "Purple", "Gold" (non-conflicting)
 *
 * Dynamic Traits (ERC-7496):
 *   - "Level": 1, 5, 10, 25, 50 (CONFLICTING - different progression)
 *   - "Class": "Beginner", "Warrior", "Mage", "Rogue", "Legend" (CONFLICTING - evolved classes)
 *   - "Guild": "None", "Warriors", "Mages", "Rogues", "Legends" (non-conflicting)
 *
 * Expected behavior:
 *   - Dynamic traits should OVERRIDE tokenURI traits for conflicting keys
 *   - Final "Level" should be: 1, 5, 10, 25, 50 (from dynamic)
 *   - Final "Class" should be: "Beginner", "Warrior", "Mage", "Rogue", "Legend" (from dynamic)
 *   - "Background" and "Guild" should both appear (no conflict)
 */
contract DeployConflicting is Script {
    // Dynamic trait keys (keccak256 hashes for consistent indexing)
    bytes32 constant LEVEL_KEY = keccak256("Level"); // CONFLICTS with tokenURI
    bytes32 constant CLASS_KEY = keccak256("Class"); // CONFLICTS with tokenURI
    bytes32 constant GUILD_KEY = keccak256("Guild"); // Does NOT conflict

    function run() public {
        vm.startBroadcast();

        // Deploy the contract
        TestNFTConflicting nft = new TestNFTConflicting();
        console2.log("Deployed TestNFTConflicting at:", address(nft));

        // Mint 5 tokens to the deployer
        address deployer = msg.sender;
        for (uint256 i = 0; i < 5; i++) {
            nft.mint(deployer);
        }
        console2.log("Minted tokens 1-5 to:", deployer);

        // Set STATIC traits (appear in tokenURI)
        // Note: Level and Class here will be OVERRIDDEN by dynamic traits
        nft.setStaticTraits(1, 1, "Peasant", "Blue");
        nft.setStaticTraits(2, 1, "Peasant", "Red");
        nft.setStaticTraits(3, 1, "Peasant", "Green");
        nft.setStaticTraits(4, 1, "Peasant", "Purple");
        nft.setStaticTraits(5, 1, "Peasant", "Gold");
        console2.log("Set static traits (Level=1, Class=Peasant, Background=varied)");

        // Set DYNAMIC traits (these should override static Level and Class)
        // Token 1: Beginner (dynamic Level=1, same as static - edge case!)
        nft.setTrait(1, LEVEL_KEY, bytes32(uint256(1)));
        nft.setTrait(1, CLASS_KEY, bytes32("Beginner"));
        nft.setTrait(1, GUILD_KEY, bytes32("None"));

        // Token 2: Warrior (dynamic Level=5, overrides static Level=1)
        nft.setTrait(2, LEVEL_KEY, bytes32(uint256(5)));
        nft.setTrait(2, CLASS_KEY, bytes32("Warrior"));
        nft.setTrait(2, GUILD_KEY, bytes32("Warriors"));

        // Token 3: Mage (dynamic Level=10, overrides static Level=1)
        nft.setTrait(3, LEVEL_KEY, bytes32(uint256(10)));
        nft.setTrait(3, CLASS_KEY, bytes32("Mage"));
        nft.setTrait(3, GUILD_KEY, bytes32("Mages"));

        // Token 4: Rogue (dynamic Level=25, overrides static Level=1)
        nft.setTrait(4, LEVEL_KEY, bytes32(uint256(25)));
        nft.setTrait(4, CLASS_KEY, bytes32("Rogue"));
        nft.setTrait(4, GUILD_KEY, bytes32("Rogues"));

        // Token 5: Legend (dynamic Level=50, overrides static Level=1)
        nft.setTrait(5, LEVEL_KEY, bytes32(uint256(50)));
        nft.setTrait(5, CLASS_KEY, bytes32("Legend"));
        nft.setTrait(5, GUILD_KEY, bytes32("Legends"));

        console2.log("Set dynamic traits (Level=varied, Class=evolved, Guild=varied)");

        // Build on-chain trait metadata JSON
        string memory traitMetadataJson = _buildTraitMetadataJson();
        string memory traitMetadataURI = Metadata.base64JsonDataURI(traitMetadataJson);
        nft.setTraitMetadataURI(traitMetadataURI);
        console2.log("Set trait metadata URI (on-chain)");

        vm.stopBroadcast();

        // Log summary
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("Contract: TestNFTConflicting");
        console2.log("Address:", address(nft));
        console2.log("Tokens minted: 5");
        console2.log("");
        console2.log("tokenURI traits:");
        console2.log("  - Level: 1 (all tokens)");
        console2.log("  - Class: Peasant (all tokens)");
        console2.log("  - Background: Blue, Red, Green, Purple, Gold");
        console2.log("");
        console2.log("Dynamic traits:");
        console2.log("  - Level: 1, 5, 10, 25, 50");
        console2.log("  - Class: Beginner, Warrior, Mage, Rogue, Legend");
        console2.log("  - Guild: None, Warriors, Mages, Rogues, Legends");
        console2.log("");
        console2.log("CONFLICTS on: Level, Class");
        console2.log("Expected: Dynamic traits override tokenURI for conflicts");
    }

    /// @dev Builds the ERC-7496 trait metadata JSON on-chain
    function _buildTraitMetadataJson() internal pure returns (string memory) {
        // Level trait - unsigned integer (CONFLICTS with tokenURI)
        string memory levelTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Level"),
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

        // Class trait - string (CONFLICTS with tokenURI)
        string memory classTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Class"),
                json.rawProperty("dataType", json.objectOf(Solarray.strings(json.property("type", "string"))))
            )
        );

        // Guild trait - string (no conflict)
        string memory guildTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Guild"),
                json.rawProperty("dataType", json.objectOf(Solarray.strings(json.property("type", "string"))))
            )
        );

        // Combine all traits into the root object
        string memory traits = json.objectOf(
            Solarray.strings(
                json.rawProperty("Level", levelTrait),
                json.rawProperty("Class", classTrait),
                json.rawProperty("Guild", guildTrait)
            )
        );

        return json.objectOf(Solarray.strings(json.rawProperty("traits", traits)));
    }
}
