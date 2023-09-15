// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERCDynamicTraits {
    event TraitUpdated(uint256 indexed tokenId, bytes32 indexed traitKey, bytes32 oldValue, bytes32 newValue);
    event TraitBulkUpdated(uint256 indexed fromTokenId, uint256 indexed toTokenId, bytes32 indexed traitKeyPattern);

    function getTrait(uint256 tokenId, bytes32 traitKey) external view returns (bytes32);
}
