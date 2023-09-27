// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721ConduitPreapproved_Solady, ERC721} from "../tokens/erc721/ERC721ConduitPreapproved_Solady.sol";
import {json} from "../onchain/json.sol";
import {svg} from "../onchain/svg.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Solarray} from "solarray/Solarray.sol";
import {Metadata} from "../onchain/Metadata.sol";

import {OnchainTraits, DynamicTraits} from "../dynamic-traits/OnchainTraits.sol";

abstract contract AbstractNFT is OnchainTraits, ERC721ConduitPreapproved_Solady {
    string _name;
    string _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Get the metdata URI for a given token ID
     * @param tokenId The token ID to get the tokenURI for
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return _stringURI(tokenId);
    }

    /**
     * @notice Helper function to get the raw JSON metadata representing a given token ID
     * @param tokenId The token ID to get URI for
     */
    function _stringURI(uint256 tokenId) internal view virtual returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("name", string.concat("Example NFT #", LibString.toString(tokenId))),
                json.property("description", "This is an example NFT"),
                json.property("image", Metadata.base64SvgDataURI(_image(tokenId))),
                _attributes(tokenId)
            )
        );
    }

    /**
     * @notice Helper function to get both the static and dynamic attributes for a given token ID
     * @param tokenId The token ID to get the static and dynamic attributes for
     */
    function _attributes(uint256 tokenId) internal view virtual returns (string memory) {
        // get the static attributes
        string[] memory staticTraits = _staticAttributes(tokenId);
        // get the dynamic attributes
        string[] memory dynamicTraits = _dynamicAttributes(tokenId);

        // return the combined attributes as a property containing an array
        return json.rawProperty("attributes", json.arrayOf(staticTraits, dynamicTraits));
    }

    /**
     * @notice Helper function to get the static attributes for a given token ID
     * @param tokenId The token ID to get the static attributes for
     */
    function _staticAttributes(uint256 tokenId) internal view virtual returns (string[] memory);

    /**
     * @notice Helper function to get the raw SVG image for a given token ID
     * @param tokenId The token ID to get the dynamic attributes for
     */
    function _image(uint256 tokenId) internal view virtual returns (string memory);

    function supportsInterface(bytes4 interfaceId) public view virtual override(DynamicTraits, ERC721) returns (bool) {
        return DynamicTraits.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }
}
