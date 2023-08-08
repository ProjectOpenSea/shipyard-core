// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ERC721ConduitPreapproved_Solady, ERC721
} from "shipyard-core/tokens/erc721/ERC721ConduitPreapproved_Solady.sol";

contract ERC721_Solady is ERC721ConduitPreapproved_Solady {
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function name() public pure override returns (string memory) {
        return "Test";
    }

    function symbol() public pure override returns (string memory) {
        return "TST";
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "https://example.com";
    }
}
