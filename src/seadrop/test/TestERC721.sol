// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC721} from "solady/tokens/ERC721.sol";

// Used for minting test ERC721s in our tests
contract TestERC721 is ERC721 {
    function name() public pure override returns (string memory) {
        return "TestERC721";
    }

    function symbol() public pure override returns (string memory) {
        return "TEST";
    }

    function mint(address to, uint256 tokenId) public returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "tokenURI";
    }
}
