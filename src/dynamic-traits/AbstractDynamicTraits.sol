// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {DynamicTraits} from "./DynamicTraits.sol";

abstract contract AbstractDynamicTraits is DynamicTraits, Ownable {
    constructor() {
        _traitLabelsURI = "https://example.com";
        _initializeOwner(msg.sender);
    }

    function setTrait(bytes32 traitKey, uint256 tokenId, bytes32 value) external virtual override onlyOwner {
        _setTrait(traitKey, tokenId, value);
    }

    function deleteTrait(bytes32 traitKey, uint256 tokenId) external virtual override onlyOwner {
        _deleteTrait(traitKey, tokenId);
    }

    function setTraitLabelsURI(string calldata uri) external onlyOwner {
        _setTraitLabelsURI(uri);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(DynamicTraits) returns (bool) {
        return DynamicTraits.supportsInterface(interfaceId);
    }
}
