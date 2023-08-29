// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OptionalTrait} from "../interfaces/IERCDynamicTraits.sol";

type OptionalValue is uint256;

using OptionalValueType for OptionalValue global;

struct OptionalValueStorage {
    OptionalValue value;
    bytes32 fullWidthSlot;
}

library OptionalValueType {
    uint256 constant IS_FULL_WIDTH_LEFT_OFFSET = 1;
    uint256 constant VALUE_LEFT_OFFSET = 2;
    // 0b11
    uint256 constant EXISTS_AND_FULL_WIDTH = 3;

    function empty() internal pure returns (OptionalValue _value) {}

    function create(bytes32 value) internal pure returns (OptionalValue _value) {
        assembly {
            _value :=
                or(
                    1,
                    // clear bottom 2 bits
                    shl(VALUE_LEFT_OFFSET, shr(VALUE_LEFT_OFFSET, value))
                )
        }
    }

    function createFullWidthPlaceholder() internal pure returns (OptionalValue _value) {
        assembly {
            _value := EXISTS_AND_FULL_WIDTH
        }
    }

    function exists(OptionalValue value) internal pure returns (bool _exists) {
        assembly {
            _exists := and(value, 1)
        }
    }

    function isFullWidth(OptionalValue value) internal pure returns (bool _isFullWidth) {
        assembly {
            _isFullWidth := and(shr(IS_FULL_WIDTH_LEFT_OFFSET, value), 1)
        }
    }

    function unwrapOr(OptionalValue value, bytes32 ifEmpty) internal pure returns (bytes32 _unwrapped) {
        assembly {
            let _empty := and(value, 1)
            _unwrapped :=
                or(
                    // value if not empty, zero if empty
                    mul(
                        iszero(_empty),
                        // clear bottom two bits
                        shl(VALUE_LEFT_OFFSET, shr(VALUE_LEFT_OFFSET, value))
                    ),
                    // ifEmpty if empty, zero if not empty
                    mul(_empty, ifEmpty)
                )
        }
    }
}

library OptionalValueStorageLib {
    function load(OptionalValueStorage storage self) internal view returns (OptionalTrait memory trait) {
        OptionalValue stored = self.value;
        if (!stored.exists()) {
            return trait;
        }
        trait.exists = true;
        if (stored.isFullWidth()) {
            trait.value = self.fullWidthSlot;
        } else {
            trait.value = stored.unwrapOr(0);
        }
        return trait;
    }

    function store(OptionalValueStorage storage self, OptionalTrait memory trait) internal {
        if (trait.exists) {
            store(self, trait.value);
        } else {
            if (self.value.isFullWidth()) {
                self.fullWidthSlot = bytes32(0);
            }
            self.value = OptionalValueType.empty();
        }
    }

    function store(OptionalValueStorage storage self, bytes32 value) internal {
        if (uint256(value) & OptionalValueType.EXISTS_AND_FULL_WIDTH != 0) {
            self.value = OptionalValueType.createFullWidthPlaceholder();
            self.fullWidthSlot = value;
        } else {
            self.value = OptionalValueType.create(value);
        }
    }
}
