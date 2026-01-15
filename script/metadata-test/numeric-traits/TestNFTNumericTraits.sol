// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {json} from "src/onchain/json.sol";
import {Metadata, DisplayType} from "src/onchain/Metadata.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {Solarray} from "solarray/Solarray.sol";

/**
 * @title TestNFTNumericTraits
 * @notice Test contract with static numeric traits for testing OpenSea Numeric Trait Offers.
 *         Uses tokenURI metadata with deterministic trait values based on tokenId.
 *
 *         Traits and their ranges:
 *         - "Power" (1-9): Single digit values
 *         - "Speed" (10-99): Double digit values
 *         - "Energy" (100-999): Triple digit values
 *         - "Experience" (10000-999999): 5-6 digit values
 *
 *         Designed to test trait offer operators: > >= < <= =
 */
contract TestNFTNumericTraits is Ownable, ERC721 {
    using LibString for uint256;

    uint256 public currentId;

    constructor() ERC721("Numeric Traits Test", "NUMTEST") {
        _initializeOwner(msg.sender);
    }

    // ============ tokenURI with numeric attributes ============

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return Metadata.base64JsonDataURI(_stringURI(tokenId));
    }

    function _stringURI(uint256 tokenId) internal pure returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("name", string.concat("Numeric Test #", tokenId.toString())),
                json.property("description", "Test NFT with numeric traits for OpenSea trait offer testing"),
                json.rawProperty("attributes", _attributesArray(tokenId))
            )
        );
    }

    function _attributesArray(uint256 tokenId) internal pure returns (string memory) {
        return json.arrayOf(
            Solarray.strings(
                _numericAttribute("Power", getPower(tokenId)),
                _numericAttribute("Speed", getSpeed(tokenId)),
                _numericAttribute("Energy", getEnergy(tokenId)),
                _numericAttribute("Experience", getExperience(tokenId))
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

    // ============ Trait value getters (deterministic based on tokenId) ============

    /// @notice Power: 1-9 (single digit)
    /// @dev Good distribution: uses different prime multipliers and modulo
    function getPower(uint256 tokenId) public pure returns (uint256) {
        // Range: 1-9
        return (uint256(keccak256(abi.encodePacked("power", tokenId))) % 9) + 1;
    }

    /// @notice Speed: 10-99 (double digit)
    function getSpeed(uint256 tokenId) public pure returns (uint256) {
        // Range: 10-99 (90 values)
        return (uint256(keccak256(abi.encodePacked("speed", tokenId))) % 90) + 10;
    }

    /// @notice Energy: 100-999 (triple digit)
    function getEnergy(uint256 tokenId) public pure returns (uint256) {
        // Range: 100-999 (900 values)
        return (uint256(keccak256(abi.encodePacked("energy", tokenId))) % 900) + 100;
    }

    /// @notice Experience: 10000-999999 (5-6 digits)
    function getExperience(uint256 tokenId) public pure returns (uint256) {
        // Range: 10000-999999 (989,999 values)
        return (uint256(keccak256(abi.encodePacked("experience", tokenId))) % 990000) + 10000;
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
}
