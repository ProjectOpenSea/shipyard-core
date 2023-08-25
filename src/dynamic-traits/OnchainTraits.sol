// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DynamicTraits} from "./DynamicTraits.sol";
import {
    TraitLabel,
    AllowedEditor,
    Editors,
    TraitLabelLib,
    TraitLabelStorageLib,
    TraitLabelStorage,
    toBitMap
} from "./lib/TraitLabelLib.sol";
import {Metadata} from "shipyard-core/onchain/Metadata.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

abstract contract OnchainTraits is Ownable, DynamicTraits {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using {toBitMap} for AllowedEditor;
    using TraitLabelStorageLib for mapping(bytes32 => TraitLabelStorage);
    using TraitLabelStorageLib for TraitLabelStorage;
    using TraitLabelLib for TraitLabel;

    error InsufficientPrivilege();
    error TraitDoesNotExist(bytes32 traitKey);

    ///@notice a mapping of traitKey to SSTORE2 storage addresses
    mapping(bytes32 traitKey => TraitLabelStorage traitLabelStorage) public traitLabelStorage;
    EnumerableSet.AddressSet internal _customEditors;

    // ABSTRACT

    ///@notice helper to determine if the given address is has the AllowedEditor.TokenOwner privilege
    function isOwnerOrApproved(uint256 tokenId, address addr) internal view virtual returns (bool);

    // CUSTOM EDITORS

    function isCustomEditor(address editor) external view returns (bool) {
        return _customEditors.contains(editor);
    }

    function updateCustomEditor(address editor, bool insert) external onlyOwner {
        if (insert) {
            _customEditors.add(editor);
        } else {
            _customEditors.remove(editor);
        }
    }

    function getCustomEditors() external view returns (address[] memory) {
        return _customEditors.values();
    }

    function getCustomEditorsLength() external view returns (uint256) {
        return _customEditors.length();
    }

    function getCustomEditorAt(uint256 index) external view returns (address) {
        return _customEditors.at(index);
    }

    // LABELS URI

    function getTraitLabelsURI() external view virtual override returns (string memory) {
        return Metadata.jsonDataURI(getTraitLabelsJson());
    }

    function getTraitLabelsJson() internal view returns (string memory) {
        bytes32[] memory keys = _traitKeys.values();
        return traitLabelStorage.toLabelJson(keys);
    }

    function setTrait(bytes32 traitKey, uint256 tokenId, bytes32 value) external virtual {
        TraitLabelStorage memory labelStorage = traitLabelStorage[traitKey];
        if (labelStorage.storageAddress == address(0)) {
            revert TraitDoesNotExist(traitKey);
        }
        _verifySetterPrivilege(labelStorage, tokenId);
        if (labelStorage.valuesRequireValidation) {
            labelStorage.toTraitLabel().validateAcceptableValue(traitKey, value);
        }
        _setTrait(traitKey, tokenId, value);
    }

    function setTraitLabel(bytes32 traitKey, TraitLabel calldata _traitLabel) external virtual onlyOwner {
        _setTraitLabel(traitKey, _traitLabel);
    }

    function _setTraitLabel(bytes32 traitKey, TraitLabel memory _traitLabel) internal virtual {
        _traitKeys.add(traitKey);
        address storageAddress = SSTORE2.write(abi.encode(_traitLabel));
        traitLabelStorage[traitKey] =
            TraitLabelStorage(_traitLabel.editors, _traitLabel.acceptableValues.length > 0, storageAddress);
    }

    function _verifySetterPrivilege(TraitLabelStorage memory labelStorage, uint256 tokenId) internal view {
        Editors _editors = labelStorage.allowedEditors;
        uint256 editors = Editors.unwrap(_editors);
        bool err;
        // anyone
        if (editors & AllowedEditor.Anyone.toBitMap() != 0) {
            // short circuit
            return;
        }
        if (editors & AllowedEditor.Self.toBitMap() != 0) {
            err = true;
        }

        // tokenOwner
        if (editors & AllowedEditor.TokenOwner.toBitMap() != 0) {
            if (isOwnerOrApproved(tokenId, msg.sender)) {
                // short circuit
                return;
            }
            err = true;
        }
        // customEditor
        if (editors & AllowedEditor.Custom.toBitMap() != 0) {
            if (_customEditors.contains(msg.sender)) {
                // short circuit
                return;
            }
            err = true;
        }
        // contractOwner
        if (editors & AllowedEditor.ContractOwner.toBitMap() != 0) {
            if (owner() == msg.sender) {
                // short circuit
                return;
            }
            err = true;
        }

        if (err) {
            revert InsufficientPrivilege();
        }
    }

    function _dynamicAttributes(uint256 tokenId) internal view returns (string[] memory) {
        bytes32[] memory keys = _traitKeys.values();
        uint256 keysLength = keys.length;

        string[] memory attributes = new string[](keysLength);
        uint256 num;
        for (uint256 i = 0; i < keysLength;) {
            bytes32 key = keys[i];
            bytes32 value = _traits[tokenId][key];
            // TODO: this breaks with 0-value numerical traits
            if (value != bytes32(0)) {
                attributes[num] = traitLabelStorage.toAttributeJson(key, value);
                unchecked {
                    ++num;
                }
            }
            unchecked {
                ++i;
            }
        }
        ///@solidity memory-safe-assembly
        assembly {
            // update attributes with actual length
            mstore(attributes, num)
        }

        return attributes;
    }
}
