// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "solady/tokens/ERC721.sol";
import {IERC721RedemptionMintable} from "./interfaces/IERC721RedemptionMintable.sol";
import {SpentItem} from "seaport-types/lib/ConsiderationStructs.sol";

contract ERC721RedemptionMintable is ERC721, IERC721RedemptionMintable {
    address internal _MINTER;

    /// @dev Revert if the sender of mintRedemption is not the redeemable contract offerer.
    error InvalidSender();

    /// @dev Revert if the redemption spent is not the required token.
    error InvalidRedemption();

    constructor(address minter) {
        _MINTER = minter;
    }

    function mintRedemption(address to, uint256 tokenId) external returns (uint256) {
        if (msg.sender != _MINTER) revert InvalidSender();

        // Mint the same token ID redeemed.
        _mint(to, tokenId);

        return tokenId;
    }

    function name() public pure override returns (string memory) {
        return "ERC721RedemptionMintable";
    }

    function symbol() public pure override returns (string memory) {
        return "721RM";
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked("https://example.com/", tokenId));
    }

    function setMinter(address newMinter) external {
        if (msg.sender != _MINTER) revert InvalidSender();

        _setMinter(newMinter);
    }

    function _setMinter(address newMinter) internal {
        _MINTER = newMinter;
    }
}
