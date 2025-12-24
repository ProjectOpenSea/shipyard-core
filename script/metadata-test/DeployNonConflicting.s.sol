// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTNonConflicting} from "./TestNFTNonConflicting.sol";
import {json} from "src/onchain/json.sol";
import {Metadata} from "src/onchain/Metadata.sol";
import {Solarray} from "solarray/Solarray.sol";

/**
 * @title DeployNonConflicting
 * @notice Deploys TestNFTNonConflicting with sample tokens that have both
 *         tokenURI metadata AND dynamic traits with NON-OVERLAPPING keys.
 *
 * Usage:
 *   forge script script/metadata-test/DeployNonConflicting.s.sol --rpc-url <RPC> --broadcast
 *
 * tokenURI Traits (static, from tokenURI JSON):
 *   - "Background": "Blue", "Red", "Green", "Purple", "Gold"
 *   - "Rarity": "Common", "Uncommon", "Rare", "Epic", "Legendary"
 *   - "Generation": 1, 1, 2, 2, 3
 *
 * Dynamic Traits (ERC-7496):
 *   - "Level" (number): 1, 5, 10, 25, 50
 *   - "Experience" (number): 0, 100, 500, 2500, 10000
 *   - "Guild" (string): "None", "Warriors", "Mages", "Rogues", "Legends"
 *
 * Expected merged result: All 6 traits should appear in final metadata
 */
contract DeployNonConflicting is Script {
    // Dynamic trait keys
    bytes32 constant LEVEL_KEY = "Level";
    bytes32 constant EXPERIENCE_KEY = "Experience";
    bytes32 constant GUILD_KEY = "Guild";

    function run() public {
        vm.startBroadcast();

        // Deploy the contract
        TestNFTNonConflicting nft = new TestNFTNonConflicting();
        console2.log("Deployed TestNFTNonConflicting at:", address(nft));

        // Mint 5 tokens to the deployer
        address deployer = msg.sender;
        for (uint256 i = 1; i <= 5; i++) {
            nft.mintTo(deployer, i);
        }
        console2.log("Minted tokens 1-5 to:", deployer);

        // Set STATIC traits (appear in tokenURI)
        nft.setStaticTraits(1, "Blue", "Common", 1);
        nft.setStaticTraits(2, "Red", "Uncommon", 1);
        nft.setStaticTraits(3, "Green", "Rare", 2);
        nft.setStaticTraits(4, "Purple", "Epic", 2);
        nft.setStaticTraits(5, "Gold", "Legendary", 3);
        console2.log("Set static traits (Background, Rarity, Generation)");

        // Set DYNAMIC traits (different keys from static)
        // Token 1: Beginner (skip Experience=0 since that's the default)
        nft.setTrait(1, LEVEL_KEY, bytes32(uint256(1)));
        // Experience defaults to 0, so we skip setting it to avoid TraitValueUnchanged revert
        nft.setTrait(1, GUILD_KEY, bytes32("None"));

        // Token 2: Novice Warrior
        nft.setTrait(2, LEVEL_KEY, bytes32(uint256(5)));
        nft.setTrait(2, EXPERIENCE_KEY, bytes32(uint256(100)));
        nft.setTrait(2, GUILD_KEY, bytes32("Warriors"));

        // Token 3: Adept Mage
        nft.setTrait(3, LEVEL_KEY, bytes32(uint256(10)));
        nft.setTrait(3, EXPERIENCE_KEY, bytes32(uint256(500)));
        nft.setTrait(3, GUILD_KEY, bytes32("Mages"));

        // Token 4: Expert Rogue
        nft.setTrait(4, LEVEL_KEY, bytes32(uint256(25)));
        nft.setTrait(4, EXPERIENCE_KEY, bytes32(uint256(2500)));
        nft.setTrait(4, GUILD_KEY, bytes32("Rogues"));

        // Token 5: Legendary
        nft.setTrait(5, LEVEL_KEY, bytes32(uint256(50)));
        nft.setTrait(5, EXPERIENCE_KEY, bytes32(uint256(10000)));
        nft.setTrait(5, GUILD_KEY, bytes32("Legends"));

        console2.log("Set dynamic traits (Level, Experience, Guild)");

        // Build on-chain trait metadata JSON
        string memory traitMetadataJson = _buildTraitMetadataJson();
        string memory traitMetadataURI = Metadata.base64JsonDataURI(traitMetadataJson);
        nft.setTraitMetadataURI(traitMetadataURI);
        console2.log("Set trait metadata URI (on-chain)");

        vm.stopBroadcast();

        // Log summary
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("Contract: TestNFTNonConflicting");
        console2.log("Address:", address(nft));
        console2.log("Tokens minted: 5");
        console2.log("tokenURI traits: Background, Rarity, Generation");
        console2.log("Dynamic traits: Level, Experience, Guild");
        console2.log("Conflicts: NONE - all keys are unique");
    }

    /// @dev Builds the ERC-7496 trait metadata JSON on-chain
    function _buildTraitMetadataJson() internal pure returns (string memory) {
        // Level trait - unsigned integer
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
                )
            )
        );

        // Experience trait - unsigned integer
        string memory experienceTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Experience"),
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
                )
            )
        );

        // Guild trait - string
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
                json.rawProperty("Experience", experienceTrait),
                json.rawProperty("Guild", guildTrait)
            )
        );

        return json.objectOf(Solarray.strings(json.rawProperty("traits", traits)));
    }
}
