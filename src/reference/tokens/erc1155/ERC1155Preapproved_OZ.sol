// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155ConduitPreapproved_OZ, ERC1155} from "shipyard-core/tokens/erc1155/ERC1155ConduitPreapproved_OZ.sol";

contract ERC1155_OZ is ERC1155ConduitPreapproved_OZ {
    constructor() ERC1155("https://example.com") {}

    function mint(address to, uint256 tokenId, uint256 amount) public {
        bytes memory empty;
        _mint(to, tokenId, amount, empty);
    }

    function uri(uint256) public pure override returns (string memory) {
        return "https://example.com";
    }
}
