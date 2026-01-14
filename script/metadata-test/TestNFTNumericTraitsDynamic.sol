// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {DynamicTraits} from "src/dynamic-traits/DynamicTraits.sol";
import {json} from "src/onchain/json.sol";
import {Metadata, DisplayType} from "src/onchain/Metadata.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {Solarray} from "solarray/Solarray.sol";

/**
 * @title TestNFTNumericTraitsDynamic
 * @notice Test contract combining static numeric traits (tokenURI) with dynamic traits (ERC-7496).
 *         Used to test OpenSea Numeric Trait Offers with both trait sources.
 *
 *         Static traits (tokenURI):
 *         - "Power" (1-9): Single digit values
 *         - "Speed" (10-99): Double digit values
 *
 *         Dynamic traits (ERC-7496):
 *         - "Boost" (1-9): Single digit, updatable
 *         - "Score" (100-999): Triple digit, updatable
 *         - "Reputation" (10000-999999): 5-6 digits, updatable
 *
 *         Designed to test trait offer operators: > >= < <= =
 *         across both static and dynamic trait sources.
 */
contract TestNFTNumericTraitsDynamic is DynamicTraits, Ownable, ERC721 {
    using LibString for uint256;

    uint256 public currentId;

    constructor() ERC721("Numeric Traits Dynamic Test", "NUMDYN") {
        _initializeOwner(msg.sender);
    }

    // ============ tokenURI with static numeric attributes ============

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return Metadata.base64JsonDataURI(_stringURI(tokenId));
    }

    function _stringURI(uint256 tokenId) internal pure returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("name", string.concat("NumDyn Test #", tokenId.toString())),
                json.property("description", "Test NFT with static + dynamic numeric traits for OpenSea testing"),
                json.rawProperty("attributes", _attributesArray(tokenId))
            )
        );
    }

    function _attributesArray(uint256 tokenId) internal pure returns (string memory) {
        // Only static traits in tokenURI - dynamic traits come from ERC-7496
        return json.arrayOf(
            Solarray.strings(
                _numericAttribute("Power", getPower(tokenId)),
                _numericAttribute("Speed", getSpeed(tokenId))
            )
        );
    }

    function _numericAttribute(string memory traitType, uint256 value) internal pure returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("trait_type", traitType),
                json.rawProperty("value", value.toString())
            )
        );
    }

    // ============ Static trait value getters (deterministic based on tokenId) ============

    /// @notice Power: 1-9 (single digit) - STATIC
    function getPower(uint256 tokenId) public pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked("power", tokenId))) % 9) + 1;
    }

    /// @notice Speed: 10-99 (double digit) - STATIC
    function getSpeed(uint256 tokenId) public pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked("speed", tokenId))) % 90) + 10;
    }

    // ============ Dynamic traits (ERC-7496) ============

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

    // ============ Minting ============

    function mint(address to) public returns (uint256) {
        uint256 tokenId = ++currentId;
        _mint(to, tokenId);
        return tokenId;
    }

    /// @notice Bulk mint tokens to a single address
    /// @param to Recipient address
    /// @param amount Number of tokens to mint
    function bulkMint(address to, uint256 amount) public returns (uint256 startId, uint256 endId) {
        startId = currentId + 1;
        for (uint256 i = 0; i < amount;) {
            uint256 tokenId = ++currentId;
            _mint(to, tokenId);
            unchecked { ++i; }
        }
        endId = currentId;
    }

    /// @notice Batch set a single trait for multiple tokens
    /// @param tokenIds Array of token IDs
    /// @param traitKey The trait key to set
    /// @param values Array of values corresponding to each token
    function batchSetTrait(uint256[] calldata tokenIds, bytes32 traitKey, bytes32[] calldata values) external onlyOwner {
        require(tokenIds.length == values.length, "Length mismatch");
        for (uint256 i = 0; i < tokenIds.length;) {
            _requireOwned(tokenIds[i]);
            // Use internal _setTrait to skip unchanged value check and emit event
            _setTrait(tokenIds[i], traitKey, values[i]);
            emit TraitUpdated(traitKey, tokenIds[i], values[i]);
            unchecked { ++i; }
        }
    }

    /// @notice Batch set multiple traits for a range of tokens with deterministic values
    /// @param startTokenId First token ID
    /// @param endTokenId Last token ID (inclusive)
    /// @param boostSalt Salt for boost randomization
    /// @param scoreSalt Salt for score randomization  
    /// @param reputationSalt Salt for reputation randomization
    function batchSetTraitsForRange(
        uint256 startTokenId,
        uint256 endTokenId,
        bytes32 boostKey,
        bytes32 scoreKey,
        bytes32 reputationKey,
        string calldata boostSalt,
        string calldata scoreSalt,
        string calldata reputationSalt
    ) external onlyOwner {
        for (uint256 tokenId = startTokenId; tokenId <= endTokenId;) {
            _requireOwned(tokenId);
            
            // Boost: 1-9
            uint256 boost = (uint256(keccak256(abi.encodePacked(boostSalt, tokenId))) % 9) + 1;
            _setTrait(tokenId, boostKey, bytes32(boost));
            emit TraitUpdated(boostKey, tokenId, bytes32(boost));
            
            // Score: 100-999
            uint256 score = (uint256(keccak256(abi.encodePacked(scoreSalt, tokenId))) % 900) + 100;
            _setTrait(tokenId, scoreKey, bytes32(score));
            emit TraitUpdated(scoreKey, tokenId, bytes32(score));
            
            // Reputation: 10000-999999
            uint256 reputation = (uint256(keccak256(abi.encodePacked(reputationSalt, tokenId))) % 990000) + 10000;
            _setTrait(tokenId, reputationKey, bytes32(reputation));
            emit TraitUpdated(reputationKey, tokenId, bytes32(reputation));
            
            unchecked { ++tokenId; }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, DynamicTraits) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || DynamicTraits.supportsInterface(interfaceId);
    }
}
