// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERCDynamicTraits} from "../interfaces/IDynamicTraits.sol";
import {RedeemableErrorsAndEvents} from "./RedeemableErrorsAndEvents.sol";

contract DynamicTraits is IERCDynamicTraits, RedeemableErrorsAndEvents {
    mapping(uint256 tokenId => mapping(bytes32 traitKey => bytes32 traitValue)) internal _traits;

    function getTrait(uint256 tokenId, bytes32 traitKey) public view virtual override returns (bytes32) {
        return _traits[tokenId][traitKey];
    }

    function _setTrait(uint256 tokenId, bytes32 traitKey, bytes32 newValue) internal {
        bytes32 oldValue = _traits[tokenId][traitKey];

        if (oldValue == newValue) {
            revert TraitValueUnchanged(traitKey, oldValue);
        }

        _traits[tokenId][traitKey] = newValue;

        emit TraitUpdated(tokenId, traitKey, oldValue, newValue);
    }

    function _setTraitBulk(uint256 fromTokenId, uint256 toTokenId, bytes32 traitKey, bytes32 newValue) internal {
        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            _traits[tokenId][traitKey] = newValue;
        }

        emit TraitBulkUpdated(fromTokenId, toTokenId, traitKey);
    }
}
