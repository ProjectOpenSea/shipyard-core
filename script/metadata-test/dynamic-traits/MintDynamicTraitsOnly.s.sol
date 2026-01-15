// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTDynamicTraitsOnly} from "script/metadata-test/dynamic-traits/TestNFTDynamicTraitsOnly.sol";

/**
 * @title MintDynamicTraitsOnly
 * @notice Mints the next 5 tokens on an existing TestNFTDynamicTraitsOnly contract.
 *
 * Usage:
 *   forge script MintDynamicTraitsOnly \
 *     --rpc-url $BASE_RPC_URL \
 *     --private-key $PK \
 *     --broadcast \
 *     --sig "run(address)" \
 *     0x74842eaf0a5b3fe3b0e30f9ba79e9e3ec281796e
 */
contract MintDynamicTraitsOnly is Script {
    // Trait keys (keccak256 hashes for consistent indexing)
    bytes32 constant LEVEL_KEY = keccak256("Level");
    bytes32 constant EXPERIENCE_KEY = keccak256("Experience");
    bytes32 constant GUILD_KEY = keccak256("Guild");
    bytes32 constant IS_ACTIVE_KEY = keccak256("IsActive");

    function run(address contractAddress) public {
        TestNFTDynamicTraitsOnly nft = TestNFTDynamicTraitsOnly(contractAddress);

        // Read current state before broadcast
        uint256 startId = nft.currentId();
        console2.log("Contract:", contractAddress);
        console2.log("Current token ID:", startId);

        vm.startBroadcast();

        address recipient = msg.sender;

        // Mint next 5 tokens
        uint256[] memory newTokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            uint256 tokenId = nft.mint(recipient);
            newTokenIds[i] = tokenId;
            console2.log("Minted token:", tokenId);
        }

        // Set dynamic traits for the new tokens with varied values
        // Token 6: Apprentice
        nft.setTrait(newTokenIds[0], LEVEL_KEY, bytes32(uint256(3)));
        nft.setTrait(newTokenIds[0], EXPERIENCE_KEY, bytes32(uint256(50)));
        nft.setTrait(newTokenIds[0], GUILD_KEY, bytes32("Warriors"));
        nft.setTrait(newTokenIds[0], IS_ACTIVE_KEY, bytes32(uint256(1)));

        // Token 7: Journeyman
        nft.setTrait(newTokenIds[1], LEVEL_KEY, bytes32(uint256(8)));
        nft.setTrait(newTokenIds[1], EXPERIENCE_KEY, bytes32(uint256(300)));
        nft.setTrait(newTokenIds[1], GUILD_KEY, bytes32("Mages"));
        nft.setTrait(newTokenIds[1], IS_ACTIVE_KEY, bytes32(uint256(1)));

        // Token 8: Veteran
        nft.setTrait(newTokenIds[2], LEVEL_KEY, bytes32(uint256(15)));
        nft.setTrait(newTokenIds[2], EXPERIENCE_KEY, bytes32(uint256(1000)));
        nft.setTrait(newTokenIds[2], GUILD_KEY, bytes32("Rogues"));
        nft.setTrait(newTokenIds[2], IS_ACTIVE_KEY, bytes32(uint256(1)));

        // Token 9: Master
        nft.setTrait(newTokenIds[3], LEVEL_KEY, bytes32(uint256(35)));
        nft.setTrait(newTokenIds[3], EXPERIENCE_KEY, bytes32(uint256(5000)));
        nft.setTrait(newTokenIds[3], GUILD_KEY, bytes32("Legends"));
        nft.setTrait(newTokenIds[3], IS_ACTIVE_KEY, bytes32(uint256(1)));

        // Token 10: Grandmaster (inactive)
        nft.setTrait(newTokenIds[4], LEVEL_KEY, bytes32(uint256(75)));
        nft.setTrait(newTokenIds[4], EXPERIENCE_KEY, bytes32(uint256(25000)));
        nft.setTrait(newTokenIds[4], GUILD_KEY, bytes32("Legends"));
        // IS_ACTIVE defaults to 0 (inactive)

        vm.stopBroadcast();

        // Log summary
        console2.log("");
        console2.log("=== Mint Summary ===");
        console2.log("Contract:", contractAddress);
        console2.log("Tokens minted:", newTokenIds[0], "-", newTokenIds[4]);
        console2.log("Recipient:", recipient);
        console2.log("Dynamic traits set for all new tokens");
    }
}

