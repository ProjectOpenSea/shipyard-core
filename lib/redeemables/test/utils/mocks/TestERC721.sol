// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {ERC721} from "solady/src/tokens/ERC721.sol";

// Used for minting test ERC721s in our tests
contract TestERC721 is ERC721 {
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "tokenURI";
    }

    function name() public view virtual override returns (string memory) {
        return "TestERC721";
    }

    function symbol() public view virtual override returns (string memory) {
        return "TST721";
    }
}
