// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC721DynamicTraitsMultiUpdate} from "src/dynamic-traits/test/ERC721DynamicTraitsMultiUpdate.sol";
import {Solarray} from "solarray/Solarray.sol";

contract EmitDynamicTraitTestEvents is Script {
    ERC721DynamicTraitsMultiUpdate token;

    bytes32 characterKey = keccak256("character");
    bytes32 characterValue1 = bytes32("Ninja");
    bytes32 characterValue2 = bytes32("Samurai");
    bytes32 characterValue4 = bytes32("Sorcerer");
    bytes32 characterValue5 = bytes32("Wizard");
    bytes32[] characterValues = Solarray.bytes32s(characterValue1, characterValue2, characterValue4, characterValue5);

    bytes32 backgroundColorKey = keccak256("backgroundColor");
    bytes32 backgroundColorValue1 = bytes32(0);
    bytes32 backgroundColorValue2 = bytes32(uint256(1));
    bytes32 backgroundColorValue3 = bytes32(uint256(2));
    bytes32 backgroundColorValue4 = bytes32(uint256(3));
    bytes32 backgroundColorValue5 = bytes32(uint256(4));
    bytes32[] backgroundColorValues = Solarray.bytes32s(
        backgroundColorValue1,
        backgroundColorValue2,
        backgroundColorValue3,
        backgroundColorValue4,
        backgroundColorValue5
    );

    bytes32 nameKey = keccak256("name");
    bytes32 nameValue1 = bytes32(0);
    bytes32 nameValue2 = bytes32(0x92e75d5e42b80de937d204558acf69c8ea586a244fe88bc0181323fe3b9e3ebf);
    bytes32 nameValue3 = bytes32("Greg");
    bytes32 nameValue4 = bytes32(uint256(77));
    bytes32[] nameValues = Solarray.bytes32s(nameValue1, nameValue2, nameValue3, nameValue4);

    bytes32 pointsKey = keccak256("points");
    bytes32 pointsValue1 = bytes32(0);
    bytes32 pointsValue2 = bytes32(uint256(100));
    bytes32 pointsValue3 = bytes32(uint256(201));
    bytes32 pointsValue4 = bytes32(uint256(302));
    bytes32[] pointsValues = Solarray.bytes32s(pointsValue1, pointsValue2, pointsValue3, pointsValue4);

    bytes32 healthKey = keccak256("health");
    bytes32 healthValue1 = bytes32(uint256(1000));
    bytes32 healthValue2 = bytes32(uint256(943));
    bytes32 healthValue3 = bytes32(uint256(471));
    bytes32[] healthValues = Solarray.bytes32s(healthValue1, healthValue2, healthValue3);

    bytes32 birthdayKey = keccak256("birthday");
    bytes32 birthdayValue1 = bytes32(0);
    bytes32 birthdayValue2 = bytes32(uint256(677919380));
    bytes32 birthdayValue3 = bytes32(uint256(537670580));
    bytes32 birthdayValue4 = bytes32(uint256(765417860));
    bytes32[] birthdayValues = Solarray.bytes32s(birthdayValue1, birthdayValue2, birthdayValue3, birthdayValue4);

    function run() public {
        vm.startBroadcast();
        
        token = new ERC721DynamicTraitsMultiUpdate();

        // Emit TraitUpdated
        _mint(0);
        token.setTrait(0, characterKey, characterValue1);

        // Emit TraitUpdatedRange
        uint256 fromTokenId = 1;
        uint256 toTokenId = 10;
        _mint(fromTokenId, toTokenId);

        token.setTraitsRangeDifferentValues(fromTokenId, toTokenId, characterKey, _getRange(10, characterValues));
        token.setTraitsRangeDifferentValues(fromTokenId, toTokenId, backgroundColorKey, _getRange(10, characterValues));
        token.setTraitsRangeDifferentValues(fromTokenId, toTokenId, nameKey, _getRange(10, nameValues));
        token.setTraitsRangeDifferentValues(fromTokenId, toTokenId, pointsKey, _getRange(10, pointsValues));
        token.setTraitsRangeDifferentValues(fromTokenId, toTokenId, healthKey, _getRange(10, healthValues));
        token.setTraitsRangeDifferentValues(fromTokenId, toTokenId, birthdayKey, _getRange(10, birthdayValues));

        // Emit TraitUpdatedRangeUniformValue
        token.setTraitsRange(fromTokenId, toTokenId, healthKey, healthValue1);
        token.setTraitsRange(fromTokenId, toTokenId, birthdayKey, birthdayValue1);

        // Emit TraitUpdatedList
        uint256[] memory tokenIds = Solarray.uint256s(4, 7, 3, 9);
        token.setTraitsListDifferentValues(tokenIds, pointsKey, _getRange(4, pointsValues));

        // Emit TraitUpdatedListUniformValue
        token.setTraitsList(tokenIds, pointsKey, pointsValue1);

        // Emit TraitMetadataURIUpdated
        // file: dynamic-traits-test-metadata.json
        token.setTraitMetadataURI("ipfs://QmYie5q3ARkYqs2bpjtG1RxTap4zie5rDK2WQ9feLAzpKM");
    }

    function _getRange(uint256 length, bytes32[] memory values) internal pure returns (bytes32[] memory result) {
        result = new bytes32[](length);
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = values[i % values.length];
        }
    }

    function _mint(uint256 tokenId) internal {
        token.mint(address(this), tokenId);
    }

    function _mint(uint256 fromTokenId, uint256 toTokenId) internal {
        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            token.mint(address(this), tokenId);
        }
    }

    function _mint(uint256[] memory tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.mint(address(this), tokenIds[i]);
        }
    }
}
