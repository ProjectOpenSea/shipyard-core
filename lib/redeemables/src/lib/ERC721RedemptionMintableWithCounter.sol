// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "solady/src/tokens/ERC721.sol";
import {IERC721RedemptionMintable} from "../interfaces/IERC721RedemptionMintable.sol";
import {SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";

contract ERC721RedemptionMintableWithCounter is ERC721, IERC721RedemptionMintable {
    address internal immutable _REDEEMABLE_CONTRACT_OFFERER;
    address internal immutable _REDEEM_TOKEN;
    uint256 internal _tokenIdCounter;

    /// @dev Revert if the sender of mintRedemption is not the redeemable contract offerer.
    error InvalidSender();

    /// @dev Revert if the redemption spent is not the required token.
    error InvalidRedemption();

    constructor(address redeemableContractOfferer, address redeemToken) {
        _REDEEMABLE_CONTRACT_OFFERER = redeemableContractOfferer;
        _REDEEM_TOKEN = redeemToken;
    }

    function mintRedemption(address to, SpentItem[] calldata spent) external returns (uint256 tokenId) {
        if (msg.sender != _REDEEMABLE_CONTRACT_OFFERER) revert InvalidSender();

        SpentItem memory spentItem = spent[0];
        if (spentItem.token != _REDEEM_TOKEN) revert InvalidRedemption();

        // Mint the token.
        _mint(to, _tokenIdCounter);

        tokenId = _tokenIdCounter;

        _tokenIdCounter++;
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
}
