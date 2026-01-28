// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {DynamicTraits} from "src/dynamic-traits/DynamicTraits.sol";
import {Metadata} from "src/onchain/Metadata.sol";

/**
 * @title TestNFTERC20BalanceTraits
 * @notice Test NFT contract with a dynamic trait representing an ERC20 balance using 18 decimals.
 *         This is designed to test various decimal scenarios for ERC20-style values.
 *
 *         The trait key "balance" stores a uint256 value in bytes32 format,
 *         representing token amounts with 18 decimal places (same as most ERC20 tokens).
 *
 *         Examples:
 *         - 1 token = 1e18 = 1000000000000000000
 *         - 0.5 tokens = 5e17 = 500000000000000000
 *         - 0.000000000000000001 tokens = 1 (1 wei)
 *         - 1000000 tokens = 1e24 = 1000000000000000000000000
 *
 *         Test scenarios covered by deploy script:
 *         - Zero balance (default)
 *         - Wei-level amounts (1 wei, 999 wei)
 *         - Fractional with many decimals (0.123456789012345678)
 *         - Fractional with few decimals (0.5, 0.01)
 *         - Whole tokens (1, 100, 1000)
 *         - Large amounts (millions, billions)
 *         - Mixed whole + fractional (123.456789012345678901)
 */
contract TestNFTERC20BalanceTraits is DynamicTraits, Ownable, ERC721 {
    uint256 public currentId;

    constructor() ERC721("ERC20 Balance Traits Test", "ERC20BAL") {
        _initializeOwner(msg.sender);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return Metadata.base64JsonDataURI("{}");
    }

    function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 value) public virtual override onlyOwner {
        _requireOwned(tokenId);
        DynamicTraits.setTrait(tokenId, traitKey, value);
    }

    function getTraitValue(uint256 tokenId, bytes32 traitKey)
        public
        view
        virtual
        override
        returns (bytes32 traitValue)
    {
        _requireOwned(tokenId);
        return DynamicTraits.getTraitValue(tokenId, traitKey);
    }

    function getTraitValues(uint256 tokenId, bytes32[] calldata traitKeys)
        public
        view
        virtual
        override
        returns (bytes32[] memory traitValues)
    {
        _requireOwned(tokenId);
        return DynamicTraits.getTraitValues(tokenId, traitKeys);
    }

    function setTraitMetadataURI(string calldata uri) external onlyOwner {
        _setTraitMetadataURI(uri);
    }

    function setTraitMetadataURI(string calldata uri, bytes32[] calldata traitKeys) external onlyOwner {
        _setTraitMetadataURI(uri, traitKeys);
    }

    function mint(address to) public returns (uint256) {
        uint256 tokenId = ++currentId;
        _mint(to, tokenId);
        return tokenId;
    }

    /// @notice Bulk mint tokens to a single address
    function bulkMint(address to, uint256 amount) public returns (uint256 startId, uint256 endId) {
        startId = currentId + 1;
        for (uint256 i = 0; i < amount;) {
            uint256 tokenId = ++currentId;
            _mint(to, tokenId);
            unchecked { ++i; }
        }
        endId = currentId;
    }

    /// @notice Batch set a single trait for multiple tokens (skips unchanged values)
    function batchSetTrait(uint256[] calldata tokenIds, bytes32 traitKey, bytes32[] calldata values) external onlyOwner {
        require(tokenIds.length == values.length, "Length mismatch");
        for (uint256 i = 0; i < tokenIds.length;) {
            _requireOwned(tokenIds[i]);
            bytes32 currentValue = DynamicTraits.getTraitValue(tokenIds[i], traitKey);
            // Skip if value unchanged to avoid revert
            if (currentValue != values[i]) {
                _setTrait(tokenIds[i], traitKey, values[i]);
                emit TraitUpdated(traitKey, tokenIds[i], values[i]);
            }
            unchecked { ++i; }
        }
    }

    /// @notice Set trait for a single token, skipping if unchanged
    function setTraitIfChanged(uint256 tokenId, bytes32 traitKey, bytes32 value) external onlyOwner {
        _requireOwned(tokenId);
        bytes32 currentValue = DynamicTraits.getTraitValue(tokenId, traitKey);
        if (currentValue != value) {
            _setTrait(tokenId, traitKey, value);
            emit TraitUpdated(traitKey, tokenId, value);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, DynamicTraits) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || DynamicTraits.supportsInterface(interfaceId);
    }
}
