// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC721DynamicTraitsMultiUpdate} from "src/dynamic-traits/test/ERC721DynamicTraitsMultiUpdate.sol";
import {Solarray} from "solarray/Solarray.sol";

contract ERC721DynamicTraitsMultiUpdateTest is Test {
    ERC721DynamicTraitsMultiUpdate token;

    /* Events */
    event TraitUpdatedRange(bytes32 indexed traitKey, uint256 fromTokenId, uint256 toTokenId);
    event TraitUpdatedRangeUniformValue(
        bytes32 indexed traitKey, uint256 fromTokenId, uint256 toTokenId, bytes32 traitValue
    );
    event TraitUpdatedList(bytes32 indexed traitKey, uint256[] tokenIds);
    event TraitUpdatedListUniformValue(bytes32 indexed traitKey, uint256[] tokenIds, bytes32 traitValue);

    function setUp() public {
        token = new ERC721DynamicTraitsMultiUpdate();
    }

    function testEmitsTraitUpdatedRange_UniformValue() public {
        bytes32 key = bytes32("testKey");
        bytes32 value = bytes32("foo");
        uint256 fromTokenId = 1;
        uint256 toTokenId = 100;

        // Register the trait key before using it.
        token.registerTraitKey(key);

        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            token.mint(address(this), tokenId);
        }

        vm.expectEmit(true, true, true, true);
        emit TraitUpdatedRangeUniformValue(key, fromTokenId, toTokenId, value);

        token.setTraitsRange(fromTokenId, toTokenId, key, value);

        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            assertEq(token.getTraitValue(tokenId, key), value);
        }
    }

    function testEmitsTraitUpdatedRange_DifferentValues() public {
        bytes32 key = bytes32("testKey");
        uint256 fromTokenId = 1;
        uint256 toTokenId = 10;
        bytes32[] memory values = new bytes32[](10);
        for (uint256 i = 0; i < values.length; i++) {
            values[i] = bytes32(i);
        }

        // Register the trait key before using it.
        token.registerTraitKey(key);

        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            token.mint(address(this), tokenId);
        }

        vm.expectEmit(true, true, true, true);
        emit TraitUpdatedRange(key, fromTokenId, toTokenId);

        token.setTraitsRangeDifferentValues(fromTokenId, toTokenId, key, values);

        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            assertEq(token.getTraitValue(tokenId, key), values[tokenId - 1]);
        }
    }

    function testEmitsTraitUpdatedList_UniformValue() public {
        bytes32 key = bytes32("testKey");
        bytes32 value = bytes32("foo");
        uint256[] memory tokenIds = Solarray.uint256s(1, 10, 20, 50);

        // Register the trait key before using it.
        token.registerTraitKey(key);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.mint(address(this), tokenIds[i]);
        }

        vm.expectEmit(true, true, true, true);
        emit TraitUpdatedListUniformValue(key, tokenIds, value);

        token.setTraitsList(tokenIds, key, value);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(token.getTraitValue(tokenIds[i], key), value);
        }
    }

    function testEmitsTraitUpdatedList_DifferentValues() public {
        bytes32 key = bytes32("testKey");
        uint256[] memory tokenIds = Solarray.uint256s(1, 10, 20, 50);
        bytes32[] memory values = new bytes32[](tokenIds.length);
        for (uint256 i = 0; i < values.length; i++) {
            values[i] = bytes32(i * 1000);
        }

        // Register the trait key before using it.
        token.registerTraitKey(key);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.mint(address(this), tokenIds[i]);
        }

        vm.expectEmit(true, true, true, true);
        emit TraitUpdatedList(key, tokenIds);

        token.setTraitsListDifferentValues(tokenIds, key, values);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(token.getTraitValue(tokenIds[i], key), values[i]);
        }
    }
}
