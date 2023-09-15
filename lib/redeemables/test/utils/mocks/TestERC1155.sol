// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {ERC1155} from "solady/src/tokens/ERC1155.sol";

// Used for minting test ERC1155s in our tests
contract TestERC1155 is ERC1155 {
    function mint(address to, uint256 tokenId, uint256 amount) public returns (bool) {
        _mint(to, tokenId, amount, "");
        return true;
    }

    function uri(uint256) public pure override returns (string memory) {
        return "uri";
    }
}
