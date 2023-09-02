// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DisplayType, Metadata} from "shipyard-core/onchain/Metadata.sol";
import {json} from "shipyard-core/onchain/json.sol";
import {Solarray} from "solarray/Solarray.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";

///@notice Bitmap type for storing allowed editors
type Editors is uint8;

///@notice alias type for storing and loading TraitLabels using SSTORE2
type StoredTraitLabel is address;

///@notice Enumeration of allowed editor roles
enum AllowedEditor {
    Anyone,
    Self,
    TokenOwner,
    Custom,
    ContractOwner
}

///@notice Struct associating a bytes32 traitValue to its string representation
struct FullTraitValue {
    bytes32 traitValue;
    string fullTraitValue;
}

///@notice Struct representing a trait label
struct TraitLabel {
    // The full trait key string if different from the bytes32 traitKey
    string fullTraitKey;
    // The string label for the trait
    string traitLabel;
    // The list of acceptable values for the trait, if it must be validated
    string[] acceptableValues;
    // The list of full trait values, if the trait value should be converted to a different string
    FullTraitValue[] fullTraitValues;
    // The display type for the trait
    DisplayType displayType;
    // The list of editors allowed to set the trait
    Editors editors;
    // Whether the trait is required to have a value
    bool required;
}

// Pack allowedEditors and valueRequiresValidation (for writes) plus storageAddress (for reads) into a single slot
struct TraitLabelStorage {
    // The bitmap of editors allowed to set the trait
    Editors allowedEditors;
    // true if TraitLabel.required == true
    bool required;
    // true if TraitLabel.acceptableValues.length != 0
    bool valuesRequireValidation;
    // The address of the TraitLabel in contract storage, aliased as a StoredTraitLabel
    StoredTraitLabel storedLabel;
}

library TraitLabelStorageLib {
    /**
     * @notice Decode a TraitLabel from contract storage
     * @param labelStorage TraitLabelStorage
     */
    function toTraitLabel(TraitLabelStorage memory labelStorage) internal view returns (TraitLabel memory) {
        return StoredTraitLabelLib.load(labelStorage.storedLabel);
    }

    /**
     * @notice Given a trait key and value, render it as a properly formatted JSON attribute
     * @param traitLabelStorage Storage mapping of trait keys to TraitLabelStorage
     * @param traitKey Trait key
     * @param traitValue Trait value
     */
    function toAttributeJson(
        mapping(bytes32 traitKey => TraitLabelStorage traitLabelStorage) storage traitLabelStorage,
        bytes32 traitKey,
        bytes32 traitValue
    ) internal view returns (string memory) {
        // read and decode the trait label from contract storage
        TraitLabelStorage storage labelStorage = traitLabelStorage[traitKey];
        TraitLabel memory traitLabel = toTraitLabel(labelStorage);

        string memory actualTraitValue;
        // convert traitValue if possible

        if (traitLabel.fullTraitValues.length != 0) {
            // try to find matching FullTraitValue
            uint256 length = traitLabel.fullTraitValues.length;
            for (uint256 i = 0; i < length;) {
                FullTraitValue memory fullTraitValue = traitLabel.fullTraitValues[i];
                if (fullTraitValue.traitValue == traitValue) {
                    actualTraitValue = fullTraitValue.fullTraitValue;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
        }
        // if no match, use traitValue as-is
        if (bytes(actualTraitValue).length == 0) {
            actualTraitValue = TraitLib.toString(traitValue, traitLabel.displayType);
        }
        // render the attribute as JSON
        return Metadata.attribute({
            traitType: traitLabel.traitLabel,
            value: actualTraitValue,
            displayType: traitLabel.displayType
        });
    }

    /**
     * @notice Given trait keys, render their labels as a properly formatted JSON array
     * @param traitLabelStorage Storage mapping of trait keys to TraitLabelStorage
     * @param keys Trait keys to render labels for
     */
    function toLabelJson(mapping(bytes32 => TraitLabelStorage) storage traitLabelStorage, bytes32[] memory keys)
        internal
        view
        returns (string memory)
    {
        string[] memory result = new string[](keys.length);
        uint256 i;
        for (i; i < keys.length;) {
            bytes32 key = keys[i];
            TraitLabel memory traitLabel = TraitLabelStorageLib.toTraitLabel(traitLabelStorage[key]); //.toTraitLabel();
            result[i] = TraitLabelLib.toLabelJson(traitLabel, key);
            unchecked {
                ++i;
            }
        }
        return json.arrayOf(result);
    }
}

library FullTraitValueLib {
    /**
     * @notice Convert a FullTraitValue to a JSON object
     */
    function toJson(FullTraitValue memory fullTraitValue) internal pure returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                // TODO: is hex string appropriate here? doesn't make sense to render hashes as strings otherwise
                json.property("traitValue", LibString.toHexString(uint256(fullTraitValue.traitValue))),
                json.property("fullTraitValue", fullTraitValue.fullTraitValue)
            )
        );
    }

    /**
     * @notice Convert an array of FullTraitValues to a JSON array of objects
     */
    function toJson(FullTraitValue[] memory fullTraitValues) internal pure returns (string memory) {
        string[] memory result = new string[](fullTraitValues.length);
        for (uint256 i = 0; i < fullTraitValues.length;) {
            result[i] = toJson(fullTraitValues[i]);
            unchecked {
                ++i;
            }
        }
        return json.arrayOf(result);
    }
}

library TraitLabelLib {
    error InvalidTraitValue(bytes32 traitKey, bytes32 traitValue);

    /**
     * @notice Store a TraitLabel in contract storage using SSTORE2 and return the StoredTraitLabel
     */
    function store(TraitLabel memory self) internal returns (StoredTraitLabel) {
        return StoredTraitLabel.wrap(SSTORE2.write(abi.encode(self)));
    }

    /**
     * @notice Validate a trait value against a TraitLabel's acceptableValues
     * @param label TraitLabel
     * @param traitKey Trait key
     * @param traitValue Trait value
     */
    function validateAcceptableValue(TraitLabel memory label, bytes32 traitKey, bytes32 traitValue) internal pure {
        string[] memory acceptableValues = label.acceptableValues;
        uint256 length = acceptableValues.length;
        DisplayType displayType = label.displayType;
        if (length != 0) {
            string memory stringValue = TraitLib.toString(traitValue, displayType);
            bytes32 hashedValue = keccak256(abi.encodePacked(stringValue));
            for (uint256 i = 0; i < length;) {
                if (hashedValue == keccak256(abi.encodePacked(acceptableValues[i]))) {
                    return;
                }
                unchecked {
                    ++i;
                }
            }
            revert InvalidTraitValue(traitKey, traitValue);
        }
    }

    /**
     * @notice Convert a TraitLabel to a JSON object
     * @param label TraitLabel
     * @param traitKey Trait key for the label
     */
    function toLabelJson(TraitLabel memory label, bytes32 traitKey) internal pure returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("traitKey", TraitLib.asString(traitKey)),
                json.property(
                    "fullTraitKey",
                    bytes(label.fullTraitKey).length == 0 ? TraitLib.asString(traitKey) : label.fullTraitKey
                ),
                json.property("traitLabel", label.traitLabel),
                json.rawProperty("acceptableValues", TraitLib.toJson(label.acceptableValues)),
                json.rawProperty("fullTraitValues", FullTraitValueLib.toJson(label.fullTraitValues)),
                json.property("displayType", Metadata.toString(label.displayType)),
                json.rawProperty("editors", EditorsLib.toJson(label.editors))
            )
        );
    }
}

library TraitLib {
    /**
     * @notice Convert a bytes32 trait value to a string
     * @param key The trait value to convert
     * @param displayType The display type of the trait value
     */
    function toString(bytes32 key, DisplayType displayType) internal pure returns (string memory) {
        if (
            displayType == DisplayType.Number || displayType == DisplayType.BoostNumber
                || displayType == DisplayType.BoostPercent
        ) {
            return LibString.toString(uint256(key));
        } else {
            return asString(key);
        }
    }

    /**
     * @notice Convert a bytes32 to a string
     * @param key The bytes32 to convert
     */
    function asString(bytes32 key) internal pure returns (string memory) {
        uint256 len = _bytes32StringLength(key);
        string memory result;
        ///@solidity memory-safe-assembly
        assembly {
            // assign result to free memory pointer
            result := mload(0x40)
            // increment free memory pointer by two words
            mstore(0x40, add(0x40, result))
            // store length at result
            mstore(result, len)
            // store key at next word
            mstore(add(result, 0x20), key)
        }
        return result;
    }

    /**
     * @notice Get the "length" of a bytes32 by counting number of non-zero leading bytes
     */
    function _bytes32StringLength(bytes32 str) internal pure returns (uint256) {
        // only meant to be called in a view context, so this optimizes for bytecode size over performance
        for (uint256 i; i < 32;) {
            if (str[i] == 0) {
                return i;
            }
            unchecked {
                ++i;
            }
        }
        return 32;
    }

    /**
     * @notice Convert an array of strings to a JSON array of strings
     */
    function toJson(string[] memory acceptableValues) internal pure returns (string memory) {
        return json.arrayOf(json.quote(acceptableValues));
    }
}

library EditorsLib {
    /**
     * @notice Convert an array of AllowedEditor enum values to an Editors bitmap
     */
    function aggregate(AllowedEditor[] memory editors) internal pure returns (Editors) {
        uint256 editorsLength = editors.length;
        uint256 result;
        for (uint256 i = 0; i < editorsLength;) {
            result |= 1 << uint8(editors[i]);
            unchecked {
                ++i;
            }
        }
        return Editors.wrap(uint8(result));
    }

    /**
     * @notice Convert an Editors bitmap to an array of AllowedEditor enum values
     */
    function expand(Editors editors) internal pure returns (AllowedEditor[] memory allowedEditors) {
        uint8 _editors = Editors.unwrap(editors);
        if (_editors & 1 == 1) {
            allowedEditors = new AllowedEditor[](1);
            allowedEditors[0] = AllowedEditor.Anyone;
            return allowedEditors;
        }
        // optimistically allocate 4 slots
        AllowedEditor[] memory result = new AllowedEditor[](4);
        uint256 num;
        for (uint256 i = 1; i < 5;) {
            bool set = _editors & (1 << i) != 0;
            if (set) {
                result[num] = AllowedEditor(i);
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
            mstore(result, num)
        }
        return result;
    }

    /**
     * @notice Convert an AllowedEditor enum value to its corresponding bit in an Editors bitmap
     */
    function toBitMap(AllowedEditor editor) internal pure returns (uint8) {
        return uint8(1 << uint256(editor));
    }

    /**
     * @notice Check if an Editors bitmap contains a given AllowedEditor
     */
    function contains(Editors self, AllowedEditor editor) internal pure returns (bool) {
        return Editors.unwrap(self) & toBitMap(editor) != 0;
    }

    /**
     * @notice Convert an Editors bitmap to a JSON array of numbers
     */
    function toJson(Editors editors) internal pure returns (string memory) {
        return toJson(expand(editors));
    }

    /**
     * @notice Convert an array of AllowedEditors to a JSON array of numbers
     */
    function toJson(AllowedEditor[] memory editors) internal pure returns (string memory) {
        string[] memory result = new string[](editors.length);
        for (uint256 i = 0; i < editors.length;) {
            result[i] = LibString.toString(uint8(editors[i]));
            unchecked {
                ++i;
            }
        }
        return json.arrayOf(result);
    }
}

library StoredTraitLabelLib {
    /**
     * @notice Check that a StoredTraitLabel is not the zero address, ie, that it exists
     */
    function exists(StoredTraitLabel storedTraitLabel) internal pure returns (bool) {
        return StoredTraitLabel.unwrap(storedTraitLabel) != address(0);
    }

    /**
     * @notice Load a TraitLabel from contract storage using SSTORE2
     */
    function load(StoredTraitLabel storedTraitLabel) internal view returns (TraitLabel memory) {
        bytes memory data = SSTORE2.read(StoredTraitLabel.unwrap(storedTraitLabel));
        return abi.decode(data, (TraitLabel));
    }
}

using EditorsLib for Editors global;
using StoredTraitLabelLib for StoredTraitLabel global;
