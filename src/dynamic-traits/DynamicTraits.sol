// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IERCDynamicTraits} from "./interfaces/IERCDynamicTraits.sol";

contract DynamicTraits is IERCDynamicTraits {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set internal _traitKeys;
    mapping(uint256 tokenId => mapping(bytes32 traitKey => bytes32 traitValue)) internal _traits;
    string internal _traitLabelsURI;

    error TraitValueUnchanged();

    function getTraitValue(bytes32 traitKey, uint256 tokenId) external view virtual returns (bytes32 traitValue) {
        return _traits[tokenId][traitKey];
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
            result[i] = _traits[tokenIds[i]][traitKey];
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

    function _setTrait(bytes32 traitKey, uint256 tokenId, bytes32 value) internal {
        bytes32 oldValue = _traits[tokenId][traitKey];
        if (oldValue == value) {
            revert TraitValueUnchanged();
        }

        _traits[tokenId][traitKey] = value;

        // no-op if exists
        _traitKeys.add(traitKey);

        emit TraitUpdated(traitKey, tokenId, value);
    }

    function _setTraitLabelsURI(string calldata uri) internal virtual {
        _traitLabelsURI = uri;
        emit TraitLabelsURIUpdated(uri);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERCDynamicTraits).interfaceId;
    }
}
