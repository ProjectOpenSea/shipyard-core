// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DisplayType, Metadata} from "shipyard-core/onchain/Metadata.sol";
import {json} from "shipyard-core/onchain/json.sol";
import {Solarray} from "solarray/Solarray.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";

type Editors is uint8;

enum AllowedEditor {
    Anyone,
    Self,
    TokenOwner,
    Custom,
    ContractOwner
}

struct FullTraitValue {
    bytes32 traitValue;
    string fullTraitValue;
}

struct TraitLabel {
    string fullTraitKey;
    string traitLabel;
    string[] acceptableValues;
    FullTraitValue[] fullTraitValues;
    // packed
    DisplayType displayType;
    Editors editors;
}

// Pack both allowedEditors (for writes) and storageAddress (for reads) into a single slot
struct TraitLabelStorage {
    Editors allowedEditors;
    bool checkValue;
    address storageAddress;
}

library TraitLabelLib {
    error InvalidTraitValue(bytes32 traitKey, bytes32 traitValue);

    function validateAcceptableValue(TraitLabel memory label, bytes32 traitKey, bytes32 traitValue) internal pure {
        if (label.acceptableValues.length != 0) {
            string memory stringValue = toString(traitValue);
            bytes32 hashedValue = keccak256(abi.encodePacked(stringValue));
            string[] memory acceptableValues = label.acceptableValues;
            uint256 length = acceptableValues.length;
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

    function toTraitLabel(TraitLabelStorage memory labelStorage) internal view returns (TraitLabel memory) {
        bytes memory data = SSTORE2.read(labelStorage.storageAddress);
        return abi.decode(data, (TraitLabel));
    }

    function toAttributeJson(
        mapping(bytes32 traitKey => TraitLabelStorage traitLabelStorage) storage traitLabelStorage,
        bytes32 traitKey,
        bytes32 traitValue
    ) internal view returns (string memory) {
        // read and decode the trait label from contract storage
        TraitLabelStorage storage labelStorage = traitLabelStorage[traitKey];
        TraitLabel memory traitLabel = toTraitLabel(labelStorage);
        string memory actualTraitValue;
        if (traitLabel.fullTraitValues.length != 0) {
            // try to find matching FullTraitValue
            uint256 length = traitLabel.fullTraitValues.length;
            bool found;
            for (uint256 i = 0; i < length;) {
                FullTraitValue memory fullTraitValue = traitLabel.fullTraitValues[i];
                if (fullTraitValue.traitValue == traitValue) {
                    actualTraitValue = fullTraitValue.fullTraitValue;
                    found = true;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            if (!found) {
                // no matching FullTraitValue found, so use the raw traitValue
                actualTraitValue = toString(traitValue);
            }
        }
        return Metadata.attribute({
            traitType: traitLabel.traitLabel,
            value: actualTraitValue,
            displayType: traitLabel.displayType
        });
    }

    function toJson(bytes32[] memory keys, mapping(bytes32 => TraitLabelStorage) storage traitLabelStorage)
        internal
        view
        returns (string memory)
    {
        string[] memory result = new string[](keys.length);
        uint256 i;
        for (i; i < keys.length;) {
            bytes32 key = keys[i];
            TraitLabel memory traitLabel = toTraitLabel(traitLabelStorage[key]);
            // TraitLabel memory label = abi.decode()
            result[i] = toJson(key, traitLabel);
            unchecked {
                ++i;
            }
        }
        return json.arrayOf(result);
    }

    function toJson(bytes32 traitKey, TraitLabel memory label) internal pure returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("traitKey", toString(traitKey)),
                json.property("fullTraitKey", label.fullTraitKey),
                json.property("traitLabel", label.traitLabel),
                json.rawProperty("acceptableValues", toJson(label.acceptableValues)),
                json.rawProperty("fullTraitValues", toJson(label.fullTraitValues)),
                json.property("displayType", Metadata.toString(label.displayType)),
                json.property("editors", toJson(label.editors.expand().castToUints()))
            )
        );
    }

    function toJson(uint8[] memory uints) internal pure returns (string memory) {
        string[] memory result = new string[](uints.length);
        for (uint256 i = 0; i < uints.length;) {
            result[i] = LibString.toString(uints[i]);
            unchecked {
                ++i;
            }
        }
        return json.arrayOf(result);
    }

    function toJson(string[] memory acceptableValues) internal pure returns (string memory) {
        return json.arrayOf(json.quote(acceptableValues));
    }

    function toJson(FullTraitValue memory fullTraitValue) internal pure returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("traitValue", toString(fullTraitValue.traitValue)),
                json.property("fullTraitValue", fullTraitValue.fullTraitValue)
            )
        );
    }

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

    function toString(bytes32 key) internal pure returns (string memory) {
        uint256 len = bytes32StringLength(key);
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

    function bytes32StringLength(bytes32 str) internal pure returns (uint256) {
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
}

/**
 * @notice convert an array of AllowedEditor enum values to an array of uint8s
 * @param editors Array of AllowedEditor enum values
 */
function castToUints(AllowedEditor[] memory editors) pure returns (uint8[] memory result) {
    ///@solidity memory-safe-assembly
    assembly {
        result := editors
    }
}

function aggregate(AllowedEditor[] memory editors) pure returns (uint8) {
    uint256 editorsLength = editors.length;
    uint256 result;
    for (uint256 i = 0; i < editorsLength;) {
        result |= 1 << uint8(editors[i]);
        unchecked {
            ++i;
        }
    }
    return uint8(result);
}

function expand(Editors editors) pure returns (AllowedEditor[] memory allowedEditors) {
    uint8 _editors = Editors.unwrap(editors);
    require(_editors < 2 ** 5, "invalid editors");
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

function toBitMap(AllowedEditor editor) pure returns (uint256) {
    return 1 << uint256(editor);
}

using {expand} for Editors global;
using {castToUints} for AllowedEditor[];
