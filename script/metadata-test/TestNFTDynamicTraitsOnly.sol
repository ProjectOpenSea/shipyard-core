// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {DynamicTraits} from "src/dynamic-traits/DynamicTraits.sol";

/**
 * @title TestNFTDynamicTraitsOnly
 * @notice Test contract with only dynamic traits (ERC-7496), no tokenURI metadata.
 *         Used to test backend pipeline handles pure dynamic trait sources.
 */
contract TestNFTDynamicTraitsOnly is DynamicTraits, Ownable, ERC721 {
    uint256 public currentId;

    constructor() ERC721("TestNFT DynamicTraits Only", "TDTO") {
        _initializeOwner(msg.sender);
    }

    function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 value) public virtual override onlyOwner {
        _requireOwned(tokenId);
        DynamicTraits.setTrait(tokenId, traitKey, value);
    }

    function getTraitValue(uint256 tokenId, bytes32 traitKey)
        public
        view
        virtual
        override
        returns (bytes32 traitValue)
    {
        _requireOwned(tokenId);
        return DynamicTraits.getTraitValue(tokenId, traitKey);
    }

    function getTraitValues(uint256 tokenId, bytes32[] calldata traitKeys)
        public
        view
        virtual
        override
        returns (bytes32[] memory traitValues)
    {
        _requireOwned(tokenId);
        return DynamicTraits.getTraitValues(tokenId, traitKeys);
    }

    function setTraitMetadataURI(string calldata uri) external onlyOwner {
        _setTraitMetadataURI(uri);
    }

    function setTraitMetadataURI(string calldata uri, bytes32[] calldata traitKeys) external onlyOwner {
        _setTraitMetadataURI(uri, traitKeys);
    }

    function mint(address to) public returns (uint256) {
        uint256 tokenId = ++currentId;
        _mint(to, tokenId);
        return tokenId;
    }

    function mintTo(address to, uint256 tokenId) public {
        _mint(to, tokenId);
        if (tokenId > currentId) {
            currentId = tokenId;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, DynamicTraits) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || DynamicTraits.supportsInterface(interfaceId);
    }
}
