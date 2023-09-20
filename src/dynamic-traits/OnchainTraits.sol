// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DynamicTraits} from "./DynamicTraits.sol";
import {Metadata} from "shipyard-core/onchain/Metadata.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {
    TraitLabelStorage,
    TraitLabelStorageLib,
    TraitLabel,
    TraitLabelLib,
    Editors,
    StoredTraitLabel,
    AllowedEditor,
    EditorsLib,
    StoredTraitLabelLib
} from "./lib/TraitLabelLib.sol";

abstract contract OnchainTraits is Ownable, DynamicTraits {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    ///@notice Thrown when the caller does not have the privilege to set a trait
    error InsufficientPrivilege();
    ///@notice Thrown when trying to set a trait that does not exist
    error TraitDoesNotExist(bytes32 traitKey);
    ///@notice Thrown when trying to delete a trait that is required to have a value.
    error TraitIsRequired();

    ///@notice a mapping of traitKey to TraitLabelStorage metadata
    mapping(bytes32 traitKey => TraitLabelStorage traitLabelStorage) public traitLabelStorage;
    ///@notice an enumerable set of all accounts allowed to edit traits with a "Custom" editor privilege
    EnumerableSet.AddressSet internal _customEditors;

    constructor() {
        _initializeOwner(msg.sender);
    }

    // ABSTRACT

    ///@notice helper to determine if a given address has the AllowedEditor.TokenOwner privilege
    function _isOwnerOrApproved(uint256 tokenId, address addr) internal view virtual returns (bool);

    // CUSTOM EDITORS

    /**
     * @notice Check if an address is a custom editor
     * @param editor The address to check
     */
    function isCustomEditor(address editor) external view returns (bool) {
        return _customEditors.contains(editor);
    }

    /**
     * @notice Add or remove an address as a custom editor
     * @param editor The address to add or remove
     * @param insert Whether to add or remove the address
     */
    function updateCustomEditor(address editor, bool insert) external onlyOwner {
        if (insert) {
            _customEditors.add(editor);
        } else {
            _customEditors.remove(editor);
        }
    }

    /**
     * @notice Get the list of custom editors. This may revert if there are too many editors.
     */
    function getCustomEditors() external view returns (address[] memory) {
        return _customEditors.values();
    }

    /**
     * @notice Get the number of custom editors
     */
    function getCustomEditorsLength() external view returns (uint256) {
        return _customEditors.length();
    }

    /**
     * @notice Get the custom editor at a given index
     * @param index The index of the custom editor to get
     */
    function getCustomEditorAt(uint256 index) external view returns (address) {
        return _customEditors.at(index);
    }

    // LABELS URI

    /**
     * @notice Get the onchain URI for the trait labels, encoded as a JSON data URI
     */
    function getTraitLabelsURI() external view virtual override returns (string memory) {
        return Metadata.jsonDataURI(_getTraitLabelsJson());
    }

    /**
     * @notice Get the raw JSON for the trait labels
     */
    function _getTraitLabelsJson() internal view returns (string memory) {
        bytes32[] memory keys = _traitKeys.values();
        return TraitLabelStorageLib.toLabelJson(traitLabelStorage, keys);
    }

    /**
     * @notice Set a trait for a given traitKey and tokenId. Checks that the caller has permission to set the trait,
     *         and, if the TraitLabel specifies that the trait value must be validated, checks that the trait value
     *         is valid.
     * @param traitKey The trait key to get the value of
     * @param tokenId The token ID to get the trait value for
     * @param trait The trait value
     */
    function setTrait(bytes32 traitKey, uint256 tokenId, bytes32 trait) external virtual override {
        TraitLabelStorage memory labelStorage = traitLabelStorage[traitKey];
        StoredTraitLabel storedTraitLabel = labelStorage.storedLabel;
        if (!StoredTraitLabelLib.exists(storedTraitLabel)) {
            revert TraitDoesNotExist(traitKey);
        }
        _verifySetterPrivilege(labelStorage.allowedEditors, tokenId);

        if (labelStorage.valuesRequireValidation) {
            TraitLabelLib.validateAcceptableValue(StoredTraitLabelLib.load(storedTraitLabel), traitKey, trait);
        }
        _setTrait(traitKey, tokenId, trait);
    }

    /**
     * @notice Delete a trait for a given traitKey and tokenId. Checks that the caller has permission to delete the trait,
     *         and that the trait is not required to have a value.
     * @param traitKey The trait key to delete the value of
     * @param tokenId The token ID to delete the trait value for
     */
    function deleteTrait(bytes32 traitKey, uint256 tokenId) external virtual override {
        TraitLabelStorage memory labelStorage = traitLabelStorage[traitKey];
        StoredTraitLabel storedTraitLabel = labelStorage.storedLabel;
        if (!StoredTraitLabelLib.exists(storedTraitLabel)) {
            revert TraitDoesNotExist(traitKey);
        }
        _verifySetterPrivilege(labelStorage.allowedEditors, tokenId);
        if (labelStorage.required) {
            revert TraitIsRequired();
        }
        _deleteTrait(traitKey, tokenId);
    }

    /**
     * @notice Set the TraitLabel for a given traitKey. This will overwrite any existing TraitLabel for the traitKey.
     *         Traits may not be set without a corresponding TraitLabel. OnlyOwner.
     * @param traitKey The trait key to set the value of
     * @param _traitLabel The trait label to set
     */
    function setTraitLabel(bytes32 traitKey, TraitLabel calldata _traitLabel) external virtual onlyOwner {
        _setTraitLabel(traitKey, _traitLabel);
    }

    /**
     * @notice Set the TraitLabelStorage for a traitKey. Packs SSTORE2 value along with allowedEditors, required?, and
     *         valuesRequireValidation? into a single storage slot for more efficient validation when setting trait values.
     */
    function _setTraitLabel(bytes32 traitKey, TraitLabel memory _traitLabel) internal virtual {
        _traitKeys.add(traitKey);
        traitLabelStorage[traitKey] = TraitLabelStorage({
            allowedEditors: _traitLabel.editors,
            required: _traitLabel.required,
            valuesRequireValidation: _traitLabel.acceptableValues.length > 0,
            storedLabel: TraitLabelLib.store(_traitLabel)
        });
    }

    /**
     * @notice Checks that the caller has permission to set a trait for a given allowed Editors set and token ID.
     *         Reverts with InsufficientPrivilege if the caller does not have permission.
     * @param editors The allowed editors for this trait
     * @param tokenId The token ID the trait is being set for
     */
    function _verifySetterPrivilege(Editors editors, uint256 tokenId) internal view {
        // anyone
        if (EditorsLib.contains(editors, AllowedEditor.Anyone)) {
            // short circuit
            return;
        }

        // tokenOwner
        if (EditorsLib.contains(editors, AllowedEditor.TokenOwner)) {
            if (_isOwnerOrApproved(tokenId, msg.sender)) {
                // short circuit
                return;
            }
        }
        // customEditor
        if (EditorsLib.contains(editors, AllowedEditor.Custom)) {
            if (_customEditors.contains(msg.sender)) {
                // short circuit
                return;
            }
        }
        // contractOwner
        if (EditorsLib.contains(editors, AllowedEditor.ContractOwner)) {
            if (owner() == msg.sender) {
                // short circuit
                return;
            }
        }

        revert InsufficientPrivilege();
    }

    /**
     * @notice Gets the individual JSON objects for each dynamic trait set on this token by iterating over all
     *         possible traitKeys and checking if the trait is set on the token. This is extremely inefficient
     *         and should only be called offchain when rendering metadata.
     * @param tokenId The token ID to get the dynamic trait attributes for
     * @return An array of JSON objects, each representing a dynamic trait set on the token
     */
    function _dynamicAttributes(uint256 tokenId) internal view virtual returns (string[] memory) {
        bytes32[] memory keys = _traitKeys.values();
        uint256 keysLength = keys.length;

        string[] memory attributes = new string[](keysLength);
        // keep track of how many traits are actually set
        uint256 num;
        for (uint256 i = 0; i < keysLength;) {
            bytes32 key = keys[i];
            bytes32 trait = _traits[tokenId][key];
            // check that the trait is set, otherwise, skip it
            if (trait != bytes32(0)) {
                if (trait == ZERO_VALUE) {
                    trait = bytes32(0);
                }
                attributes[num] = TraitLabelStorageLib.toAttributeJson(traitLabelStorage, key, trait);
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
