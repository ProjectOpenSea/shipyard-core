// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {DynamicTraits} from "./DynamicTraits.sol";

contract ERC721DynamicTraits is DynamicTraits, Ownable, ERC721 {
    constructor() Ownable(msg.sender) ERC721("ERC721DynamicTraits", "ERC721DT") {
        _traitLabelsURI = "https://example.com";
    }

    function setTrait(bytes32 traitKey, uint256 tokenId, bytes32 value) external onlyOwner {
        _setTrait(traitKey, tokenId, value, false);
    }

    function setTrait(bytes32 traitKey, uint256 tokenId, bytes32 value, bool clear) external onlyOwner {
        _setTrait(traitKey, tokenId, value, clear);
    }

    function setTraitLabelsURI(string calldata uri) external onlyOwner {
        _setTraitLabelsURI(uri);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, DynamicTraits) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || DynamicTraits.supportsInterface(interfaceId);
    }
}
