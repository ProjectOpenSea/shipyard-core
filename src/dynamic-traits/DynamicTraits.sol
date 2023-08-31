// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IERCDynamicTraits} from "./interfaces/IERCDynamicTraits.sol";

contract DynamicTraits is IERCDynamicTraits {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    error TraitNotSet(bytes32 traitKey);
    error TraitCannotBeZeroValueHash();
    error InvalidTraitValue(bytes32 traitKey, bytes32 traitValue);

    EnumerableSet.Bytes32Set internal _traitKeys;
    mapping(uint256 tokenId => mapping(bytes32 traitKey => bytes32 traitValue)) internal _traits;
    string internal _traitLabelsURI;
    bytes32 constant ZERO_VALUE = keccak256("DYNAMIC_TRAITS_ZERO_VALUE");

    error TraitValueUnchanged();

    function getTraitValue(bytes32 traitKey, uint256 tokenId) external view virtual returns (bytes32) {
        bytes32 value = _traits[tokenId][traitKey];
        if (value == bytes32(0)) {
            revert TraitNotSet(traitKey);
        } else if (value == ZERO_VALUE) {
            return bytes32(0);
        } else {
            return value;
        }
    }

    function getTraitValues(bytes32 traitKey, uint256[] calldata tokenIds)
        external
        view
        virtual
        returns (bytes32[] memory traitValues)
    {
        uint256 length = tokenIds.length;
        bytes32[] memory result = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) {
            bytes32 value = _traits[tokenIds[i]][traitKey];
            if (value == bytes32(0)) {
                revert TraitNotSet(traitKey);
            } else if (value == ZERO_VALUE) {
                value = bytes32(0);
            } else {
                result[i] = value;
            }
        }
        return result;
    }

    function getTotalTraitKeys() external view virtual returns (uint256) {
        return _traitKeys.length();
    }

    function getTraitKeyAt(uint256 index) external view virtual returns (bytes32 traitKey) {
        return _traitKeys.at(index);
    }

    function getTraitKeys() external view virtual returns (bytes32[] memory traitKeys) {
        return _traitKeys._inner._values;
    }

    function getTraitLabelsURI() external view virtual returns (string memory labelsURI) {
        return _traitLabelsURI;
    }

    function _setTrait(bytes32 traitKey, uint256 tokenId, bytes32 newTrait, bool clear) internal {
        bytes32 existingValue = _traits[tokenId][traitKey];

        if (clear) {
            if (existingValue == bytes32(0)) {
                revert TraitValueUnchanged();
            }

            _traits[tokenId][traitKey] = bytes32(0);
            emit TraitUpdated(traitKey, tokenId, bytes32(0));
            return;
        } else {
            if (newTrait == bytes32(0)) {
                newTrait = ZERO_VALUE;
            } else if (newTrait == ZERO_VALUE) {
                revert InvalidTraitValue(traitKey, newTrait);
            }

            if (existingValue == newTrait) {
                revert TraitValueUnchanged();
            }

            // no-op if exists
            _traitKeys.add(traitKey);

            _traits[tokenId][traitKey] = newTrait;

            emit TraitUpdated(traitKey, tokenId, newTrait);
        }
    }

    function _setTraitLabelsURI(string calldata uri) internal virtual {
        _traitLabelsURI = uri;
        emit TraitLabelsURIUpdated(uri);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERCDynamicTraits).interfaceId;
    }
}
