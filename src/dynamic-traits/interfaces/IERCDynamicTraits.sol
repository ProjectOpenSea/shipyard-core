// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from "forge-std/interfaces/IERC165.sol";

struct OptionalTrait {
    bool exists;
    bytes32 value;
}

interface IERCDynamicTraits is IERC165 {
    /* Events */
    event TraitUpdated(bytes32 indexed traitKey, uint256 indexed tokenId, OptionalTrait trait);
    event TraitUpdatedBulkConsecutive(bytes32 indexed traitKeyPattern, uint256 fromTokenId, uint256 toTokenId);
    event TraitUpdatedBulkList(bytes32 indexed traitKeyPattern, uint256[] tokenIds);
    event TraitLabelsURIUpdated(string uri);

    /* Getters */
    function getTraitValue(bytes32 traitKey, uint256 tokenId) external view returns (OptionalTrait memory traitValue);
    function getTraitValues(bytes32 traitKey, uint256[] calldata tokenIds)
        external
        view
        returns (OptionalTrait[] memory traitValues);
    function getTotalTraitKeys() external view returns (uint256);
    function getTraitKeys() external view returns (bytes32[] memory traitKeys);
    function getTraitKeyAt(uint256 index) external view returns (bytes32 traitKey);
    function getTraitLabelsURI() external view returns (string memory labelsURI);

    // The set methods are optional on the public interface,
    // and should not be included when calculating the interfaceId.
    /*
    function setTrait(bytes32 traitKey, uint256 tokenId, bytes32 value) external;
    function setTraitLabelsURI(string calldata uri) external;
    */
}
