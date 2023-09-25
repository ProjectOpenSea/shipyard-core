// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721ConduitPreapproved_OZ, ERC721} from "../../../tokens/erc721/ERC721ConduitPreapproved_OZ.sol";

contract ERC721_OZ is ERC721ConduitPreapproved_OZ {
    constructor() ERC721ConduitPreapproved_OZ() ERC721("ERC721_OZ", "ERC721_OZ") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
