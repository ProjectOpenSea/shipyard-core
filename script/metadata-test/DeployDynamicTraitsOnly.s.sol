// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTDynamicTraitsOnly} from "./TestNFTDynamicTraitsOnly.sol";
import {json} from "src/onchain/json.sol";
import {Metadata} from "src/onchain/Metadata.sol";
import {Solarray} from "solarray/Solarray.sol";

/**
 * @title DeployDynamicTraitsOnly
 * @notice Deploys TestNFTDynamicTraitsOnly with sample tokens and dynamic traits.
 *         This contract has NO tokenURI metadata - only ERC-7496 dynamic traits.
 *
 * Usage:
 *   forge script script/metadata-test/DeployDynamicTraitsOnly.s.sol --rpc-url <RPC> --broadcast
 *
 * Dynamic Traits Set:
 *   - "Level" (number): 1, 5, 10, 25, 50
 *   - "Experience" (number): 0, 100, 500, 2500, 10000
 *   - "Guild" (string): "None", "Warriors", "Mages", "Rogues", "Legends"
 *   - "IsActive" (boolean as number): 0 or 1
 */
contract DeployDynamicTraitsOnly is Script {
    // Trait keys (keccak256 hashes for consistent indexing)
    bytes32 constant LEVEL_KEY = keccak256("Level");
    bytes32 constant EXPERIENCE_KEY = keccak256("Experience");
    bytes32 constant GUILD_KEY = keccak256("Guild");
    bytes32 constant IS_ACTIVE_KEY = keccak256("IsActive");

    function run() public {
        vm.startBroadcast();

        // Deploy the contract
        TestNFTDynamicTraitsOnly nft = new TestNFTDynamicTraitsOnly();
        console2.log("Deployed TestNFTDynamicTraitsOnly at:", address(nft));

        // Build on-chain trait metadata JSON and register trait keys
        string memory traitMetadataJson = _buildTraitMetadataJson();
        string memory traitMetadataURI = Metadata.base64JsonDataURI(traitMetadataJson);
        bytes32[] memory traitKeys = new bytes32[](4);
        traitKeys[0] = LEVEL_KEY;
        traitKeys[1] = EXPERIENCE_KEY;
        traitKeys[2] = GUILD_KEY;
        traitKeys[3] = IS_ACTIVE_KEY;
        nft.setTraitMetadataURI(traitMetadataURI, traitKeys);
        console2.log("Set trait metadata URI and registered trait keys");

        // Mint 5 tokens to the deployer
        address deployer = msg.sender;
        for (uint256 i = 0; i < 5; i++) {
            nft.mint(deployer);
        }
        console2.log("Minted tokens 1-5 to:", deployer);

        // Set dynamic traits for each token
        // Token 1: Beginner (skip Experience=0 since that's the default)
        nft.setTrait(1, LEVEL_KEY, bytes32(uint256(1)));
        // Experience defaults to 0, so we skip setting it to avoid TraitValueUnchanged revert
        nft.setTrait(1, GUILD_KEY, bytes32("None"));
        nft.setTrait(1, IS_ACTIVE_KEY, bytes32(uint256(1)));

        // Token 2: Novice Warrior
        nft.setTrait(2, LEVEL_KEY, bytes32(uint256(5)));
        nft.setTrait(2, EXPERIENCE_KEY, bytes32(uint256(100)));
        nft.setTrait(2, GUILD_KEY, bytes32("Warriors"));
        nft.setTrait(2, IS_ACTIVE_KEY, bytes32(uint256(1)));

        // Token 3: Adept Mage
        nft.setTrait(3, LEVEL_KEY, bytes32(uint256(10)));
        nft.setTrait(3, EXPERIENCE_KEY, bytes32(uint256(500)));
        nft.setTrait(3, GUILD_KEY, bytes32("Mages"));
        nft.setTrait(3, IS_ACTIVE_KEY, bytes32(uint256(1)));

        // Token 4: Expert Rogue (IsActive=0 is default, so skip to avoid revert)
        nft.setTrait(4, LEVEL_KEY, bytes32(uint256(25)));
        nft.setTrait(4, EXPERIENCE_KEY, bytes32(uint256(2500)));
        nft.setTrait(4, GUILD_KEY, bytes32("Rogues"));
        // IsActive defaults to 0, so we skip setting it to avoid TraitValueUnchanged revert

        // Token 5: Legendary
        nft.setTrait(5, LEVEL_KEY, bytes32(uint256(50)));
        nft.setTrait(5, EXPERIENCE_KEY, bytes32(uint256(10000)));
        nft.setTrait(5, GUILD_KEY, bytes32("Legends"));
        nft.setTrait(5, IS_ACTIVE_KEY, bytes32(uint256(1)));

        console2.log("Set dynamic traits for all tokens");

        vm.stopBroadcast();

        // Log summary
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("Contract: TestNFTDynamicTraitsOnly");
        console2.log("Address:", address(nft));
        console2.log("Tokens minted: 5");
        console2.log("Dynamic traits: Level, Experience, Guild, IsActive");
        console2.log("tokenURI traits: NONE");
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
                ),
                json.property("validateOnSale", "requireUintGte")
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
                ),
                json.property("validateOnSale", "requireUintGte")
            )
        );

        // Guild trait - string
        string memory guildTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Guild"),
                json.rawProperty("dataType", json.objectOf(Solarray.strings(json.property("type", "string"))))
            )
        );

        // IsActive trait - boolean
        string memory isActiveTrait = json.objectOf(
            Solarray.strings(
                json.property("displayName", "Is Active"),
                json.rawProperty(
                    "dataType",
                    json.objectOf(
                        Solarray.strings(
                            json.property("type", "boolean"),
                            json.rawProperty(
                                "valueMappings",
                                json.objectOf(Solarray.strings(json.property("0x0", "No"), json.property("0x1", "Yes")))
                            )
                        )
                    )
                )
            )
        );

        // Combine all traits into the root object
        string memory traits = json.objectOf(
            Solarray.strings(
                json.rawProperty("Level", levelTrait),
                json.rawProperty("Experience", experienceTrait),
                json.rawProperty("Guild", guildTrait),
                json.rawProperty("IsActive", isActiveTrait)
            )
        );

        return json.objectOf(Solarray.strings(json.rawProperty("traits", traits)));
    }
}
