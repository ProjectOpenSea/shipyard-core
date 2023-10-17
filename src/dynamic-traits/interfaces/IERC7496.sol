// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from "forge-std/interfaces/IERC165.sol";

interface IERC7496 is IERC165 {
    /* Events */
    event TraitUpdated(bytes32 indexed traitKey, uint256 indexed tokenId, bytes32 trait);
    event TraitUpdatedBulkRange(bytes32 indexed traitKeyPattern, uint256 fromTokenId, uint256 toTokenId);
    event TraitUpdatedBulkList(bytes32 indexed traitKeyPattern, uint256[] tokenIds);
    event TraitMetadataURIUpdated();

    /* Getters */
    function getTraitValue(uint256 tokenId, bytes32 traitKey) external view returns (bytes32 traitValue);
    function getTraitValues(uint256 tokenId, bytes32[] calldata traitKeys)
        external
        view
        returns (bytes32[] memory traitValues);
    function getTraitMetadataURI() external view returns (string memory uri);

    /* Setters */
    function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 value) external;
}
