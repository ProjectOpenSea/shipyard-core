// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721SeaDrop} from "../ERC721SeaDrop.sol";

interface IERC721RedemptionMintable {
    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    struct SpentItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
    }

    function mintRedemption(address to, SpentItem[] calldata spent) external returns (uint256 tokenId);
}

/**
 * @title  ERC721SeaDropRedemptionMintable
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @author Michael Cohen (notmichael.eth)
 * @notice ERC721SeaDropRedemptionMintable is a token contract that extends
 *         ERC721SeaDrop to additionally add a mintRedemption function.
 */
contract ERC721SeaDropRedemptionMintable is ERC721SeaDrop, IERC721RedemptionMintable {
    address internal immutable _REDEEMABLE_CONTRACT_OFFERER;
    address internal immutable _REDEEM_TOKEN;

    mapping(uint256 => uint256) public tokenURINumbers;

    /// @dev Revert if the sender of mintRedemption is not the redeemable contract offerer.
    error InvalidSender();

    /// @dev Revert if the redemption spent is not the required token.
    error InvalidRedemption();

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         and allowed SeaDrop addresses.
     */
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop,
        address redeemableContractOfferer,
        address redeemToken
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {
        _REDEEMABLE_CONTRACT_OFFERER = redeemableContractOfferer;
        _REDEEM_TOKEN = redeemToken;
    }

    /**
     * @notice Only callable by the Redeemable Contract Offerer.
     */
    function mintRedemption(address to, SpentItem[] calldata spent) external returns (uint256 tokenId) {
        if (msg.sender != _REDEEMABLE_CONTRACT_OFFERER) revert InvalidSender();

        SpentItem memory spentItem = spent[0];
        if (spentItem.token != _REDEEM_TOKEN) revert InvalidRedemption();

        // Mint the same token ID redeemed.
        _mint(to, 1);

        return _nextTokenId() - 1;
    }

    /**
     * @notice Hook to set tokenURINumber on mint.
     */
    function _beforeTokenTransfers(address from, address, /* to */ uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        // Set tokenURINumbers on mint.
        if (from == address(0)) {
            for (uint256 i = 0; i < quantity; i++) {
                // 60% chance of tokenURI 1
                // 30% chance of tokenURI 2
                // 10% chance of tokenURI 3

                // block.prevrandao returns PREVRANDAO on Ethereum post-merge
                // NOTE: do not use this on other chains
                uint256 randomness = (uint256(keccak256(abi.encode(block.prevrandao))) % 100) + 1;

                uint256 tokenURINumber = 1;
                if (randomness >= 60 && randomness < 90) {
                    tokenURINumber = 2;
                } else if (randomness >= 90) {
                    tokenURINumber = 3;
                }

                tokenURINumbers[startTokenId + i] = tokenURINumber;
            }
        }
    }

    /*
     * @notice Overrides the `tokenURI()` function to return baseURI + 1, 2, or 3
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        uint256 tokenURINumber = tokenURINumbers[tokenId];

        return string(abi.encodePacked(baseURI, _toString(tokenURINumber)));
    }
}
