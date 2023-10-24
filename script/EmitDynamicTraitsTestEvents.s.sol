// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC721DynamicTraitsMultiUpdate} from "src/dynamic-traits/test/ERC721DynamicTraitsMultiUpdate.sol";
import {Solarray} from "solarray/Solarray.sol";

contract EmitDynamicTraitTestEvents is Script {
    function run() public {
        ERC721DynamicTraitsMultiUpdate token = new ERC721DynamicTraitsMultiUpdate();

        bytes32 key = bytes32("testKey");
        bytes32 value = bytes32("foo");

        // Emit TraitUpdated
        token.mint(address(this), 1);
        token.setTrait(1, key, value);

        // Emit TraitUpdatedRange
        uint256 fromTokenId = 1;
        uint256 toTokenId = 10;
        bytes32[] memory values = new bytes32[](10);
        for (uint256 i = 0; i < values.length; i++) {
            values[i] = bytes32(i);
        }
        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            token.mint(address(this), tokenId);
        }
        token.setTraitsRangeDifferentValues(fromTokenId, toTokenId, key, values);

        // Emit TraitUpdatedRangeUniformValue
        token.setTraitsRange(fromTokenId, toTokenId, key, value);

        // Emit TraitUpdatedList
        uint256[] memory tokenIds = Solarray.uint256s(1, 10, 20, 50);
        values = new bytes32[](tokenIds.length);
        for (uint256 i = 0; i < values.length; i++) {
            values[i] = bytes32(i * 1000);
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.mint(address(this), tokenIds[i]);
        }
        token.setTraitsListDifferentValues(tokenIds, key, values);

        // Emit TraitUpdatedListUniformValue
        token.setTraitsList(tokenIds, key, value);

        // Emit TraitMetadataURIUpdated
        token.setTraitMetadataURI("http://example.com/1");
    }
}
