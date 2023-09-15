interface IERC7XXX {
    /* Events */
    event TraitUpdated(uint256 indexed tokenId, bytes32 indexed traitKey, bytes32 value);
    event TraitUpdatedBulkConsecutive(uint256 fromTokenId, uint256 toTokenId, bytes32 indexed traitKeyPattern);
    event TraitUpdatedBulkList(uint256[] tokenIds, bytes32 indexed traitKeyPattern);
    event TraitLabelsURIUpdated(string uri);

    /* Getters */
    function getTrait(bytes32 traitKey, uint256 tokenId) external view returns (bytes32);

    // function getTotalTraitKeys() external view returns (uint256);

    // function getTraitKeyAt(uint256 index) external view returns (bytes32);

    // function getTraitLabelsURI() external view returns (string memory);

    // TODO to consider:
    // function getTraitKeys() external view returns (bytes32[] memory);

    function getTraits(bytes32 traitKey, uint256[] calldata tokenIds) external view returns (bytes32[] memory);

    /* Setters */
    function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 value) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // function setTraitLabelsURI(string calldata uri) external;
}
