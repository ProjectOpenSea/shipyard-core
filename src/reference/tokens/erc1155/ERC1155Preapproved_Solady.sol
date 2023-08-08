// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ERC1155ConduitPreapproved_Solady,
    ERC1155
} from "shipyard-core/tokens/erc1155/ERC1155ConduitPreapproved_Solady.sol";

contract ERC1155_Solady is ERC1155ConduitPreapproved_Solady {
    function mint(address to, uint256 tokenId, uint256 amount) public {
        _mint(to, tokenId, amount, "");
    }

    function uri(uint256) public pure override returns (string memory) {
        return "https://example.com";
    }
}
