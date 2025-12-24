// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {DynamicTraits} from "src/dynamic-traits/DynamicTraits.sol";
import {json} from "src/onchain/json.sol";
import {Metadata} from "src/onchain/Metadata.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {Solarray} from "solarray/Solarray.sol";
import {Base64} from "solady/src/utils/Base64.sol";

/**
 * @title TestNFTConflicting
 * @notice Test contract with both dynamic traits AND tokenURI metadata traits
 *         where SOME trait keys CONFLICT (same key in both sources).
 *
 *         tokenURI traits: "Level", "Class", "Background" (Level and Class conflict!)
 *         Dynamic traits: "Level", "Class", "Guild" (Level and Class conflict!)
 *
 *         This tests how the backend pipeline resolves conflicts.
 *         Expected behavior: Dynamic traits should override tokenURI traits.
 */
contract TestNFTConflicting is DynamicTraits, Ownable, ERC721 {
    uint256 public currentId;

    // Static trait data stored per token (some will conflict with dynamic traits)
    mapping(uint256 => uint256) public tokenLevel; // CONFLICTS with dynamic "Level"
    mapping(uint256 => string) public tokenClass; // CONFLICTS with dynamic "Class"
    mapping(uint256 => string) public tokenBackground; // Non-conflicting

    constructor() ERC721("TestNFT Conflicting", "TCNF") {
        _initializeOwner(msg.sender);
    }

    // ============ tokenURI with static attributes ============

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return Metadata.base64JsonDataURI(_stringURI(tokenId));
    }

    function _stringURI(uint256 tokenId) internal view returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("name", string.concat("Conflicting Test #", LibString.toString(tokenId))),
                json.property("description", "Test NFT with CONFLICTING dynamic and tokenURI traits"),
                json.rawProperty("attributes", _attributesArray(tokenId))
            )
        );
    }

    function _attributesArray(uint256 tokenId) internal view returns (string memory) {
        // These STATIC traits include "Level" and "Class" which will CONFLICT
        // with dynamic traits of the same names
        return json.arrayOf(
            Solarray.strings(
                // CONFLICTING: Dynamic trait "Level" should override this
                Metadata.attribute("Level", LibString.toString(tokenLevel[tokenId])),
                // CONFLICTING: Dynamic trait "Class" should override this
                Metadata.attribute("Class", tokenClass[tokenId]),
                // NON-CONFLICTING: Only exists in tokenURI
                Metadata.attribute("Background", tokenBackground[tokenId])
            )
        );
    }

    // ============ Static trait setters ============

    function setStaticTraits(uint256 tokenId, uint256 level, string calldata class_, string calldata background)
        external
        onlyOwner
    {
        tokenLevel[tokenId] = level;
        tokenClass[tokenId] = class_;
        tokenBackground[tokenId] = background;
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

    // ============ Minting ============

    function mint(address to) public returns (uint256) {
        uint256 tokenId = ++currentId;
        _mint(to, tokenId);
        return tokenId;
    }

    function mintTo(address to, uint256 tokenId) public {
        _mint(to, tokenId);
        if (tokenId > currentId) {
            currentId = tokenId;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, DynamicTraits) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || DynamicTraits.supportsInterface(interfaceId);
    }
}
