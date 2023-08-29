// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {OptionalTrait, IERCDynamicTraits} from "./interfaces/IERCDynamicTraits.sol";
import {
    OptionalValueStorage, OptionalValue, OptionalValueStorageLib, OptionalValueType
} from "./lib/DynamicTraitLib.sol";

contract DynamicTraits is IERCDynamicTraits {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using OptionalValueStorageLib for OptionalValueStorage;

    EnumerableSet.Bytes32Set internal _traitKeys;
    mapping(uint256 tokenId => mapping(bytes32 traitKey => OptionalValueStorage traitValue)) internal _traits;
    string internal _traitLabelsURI;

    error TraitValueUnchanged();

    function getTraitValue(bytes32 traitKey, uint256 tokenId)
        external
        view
        virtual
        returns (OptionalTrait memory traitValue)
    {
        return _traits[tokenId][traitKey].load();
    }

    function getTraitValues(bytes32 traitKey, uint256[] calldata tokenIds)
        external
        view
        virtual
        returns (OptionalTrait[] memory traitValues)
    {
        uint256 length = tokenIds.length;
        OptionalTrait[] memory result = new OptionalTrait[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = _traits[tokenIds[i]][traitKey].load();
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

    function _setTrait(bytes32 traitKey, uint256 tokenId, OptionalTrait memory newTrait) internal {
        OptionalValueStorage storage existingStorage = _traits[tokenId][traitKey];
        OptionalTrait memory loaded = existingStorage.load();

        if (loaded.exists == newTrait.exists && loaded.value == newTrait.value) {
            revert TraitValueUnchanged();
        }

        existingStorage.store(newTrait);

        // no-op if exists
        _traitKeys.add(traitKey);

        emit TraitUpdated(traitKey, tokenId, newTrait);
    }

    function _setTraitLabelsURI(string calldata uri) internal virtual {
        _traitLabelsURI = uri;
        emit TraitLabelsURIUpdated(uri);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERCDynamicTraits).interfaceId;
    }
}
