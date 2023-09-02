// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {OnchainTraits} from "./OnchainTraits.sol";
import {DynamicTraits} from "./DynamicTraits.sol";

contract ERC721OnchainTraits is OnchainTraits, ERC721 {
    constructor() ERC721("ERC721DynamicTraits", "ERC721DT") {
        _traitLabelsURI = "https://example.com";
    }

    function isOwnerOrApproved(uint256 tokenId, address addr) internal view virtual override returns (bool) {
        return addr == ownerOf(tokenId) || isApprovedForAll(ownerOf(tokenId), addr) || getApproved(tokenId) == addr;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, DynamicTraits) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || DynamicTraits.supportsInterface(interfaceId);
    }
}
