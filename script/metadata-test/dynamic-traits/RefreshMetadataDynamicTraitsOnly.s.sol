// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTDynamicTraitsOnly} from "script/metadata-test/dynamic-traits/TestNFTDynamicTraitsOnly.sol";

/**
 * @title RefreshMetadataDynamicTraitsOnly
 * @notice Emits TraitMetadataURIUpdated event to trigger backend reprocessing.
 *         Re-sets the existing trait metadata URI to emit the refresh event.
 *
 * Usage:
 *   forge script RefreshMetadataDynamicTraitsOnly \
 *     --rpc-url $BASE_RPC_URL \
 *     --private-key $PK \
 *     --broadcast \
 *     --sig "run(address)" \
 *     0x74842eaf0a5b3fe3b0e30f9ba79e9e3ec281796e
 */
contract RefreshMetadataDynamicTraitsOnly is Script {
    function run(address contractAddress) public {
        TestNFTDynamicTraitsOnly nft = TestNFTDynamicTraitsOnly(contractAddress);

        // Read current state
        string memory currentUri = nft.getTraitMetadataURI();
        uint256 currentId = nft.currentId();

        console2.log("Contract:", contractAddress);
        console2.log("Current token count:", currentId);
        console2.log("Current trait metadata URI length:", bytes(currentUri).length);

        vm.startBroadcast();

        // Re-set the trait metadata URI to emit TraitMetadataURIUpdated event
        // This signals to backends/indexers that they should reprocess trait data
        nft.setTraitMetadataURI(currentUri);

        vm.stopBroadcast();

        console2.log("");
        console2.log("=== Refresh Summary ===");
        console2.log("Emitted: TraitMetadataURIUpdated()");
        console2.log("Backends listening for this event should reprocess all token traits");
    }
}

