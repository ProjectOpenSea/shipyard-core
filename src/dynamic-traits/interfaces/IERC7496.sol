// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

interface IERC7496 {
    /* Errors */
    /// @notice Thrown when trying to set a trait that does not exist.
    error TraitDoesNotExist(bytes32 traitKey);
    // Note: TokenDoesNotExist(uint256 tokenId) is specified in ERC-7496 but omitted here
    // to avoid conflicts with token contracts that define their own error (e.g., Solady ERC721).
    // Implementations MAY use their underlying token's error for non-existent tokens.

    /* Events */
    event TraitUpdated(bytes32 indexed traitKey, uint256 tokenId, bytes32 traitValue);
    event TraitUpdatedRange(bytes32 indexed traitKey, uint256 fromTokenId, uint256 toTokenId);
    event TraitUpdatedRangeUniformValue(
        bytes32 indexed traitKey, uint256 fromTokenId, uint256 toTokenId, bytes32 traitValue
    );
    event TraitUpdatedList(bytes32 indexed traitKey, uint256[] tokenIds);
    event TraitUpdatedListUniformValue(bytes32 indexed traitKey, uint256[] tokenIds, bytes32 traitValue);
    event TraitMetadataURIUpdated();

    /* Getters */
    function getTraitValue(uint256 tokenId, bytes32 traitKey) external view returns (bytes32 traitValue);
    function getTraitValues(uint256 tokenId, bytes32[] calldata traitKeys)
        external
        view
        returns (bytes32[] memory traitValues);
    function getTraitMetadataURI() external view returns (string memory uri);

    /* Setters */
    function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 traitValue) external;

    /* Errors */
    error TraitValueUnchanged();
}
