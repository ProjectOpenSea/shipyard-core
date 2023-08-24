// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseSIPDecoder} from "./BaseSIPDecoder.sol";
import {Comparator, DynamicTraitRestraint} from "./SIP15Encoder.sol";

library SIP15Decoder {
    function decodeSubstandard1(bytes calldata data, uint256 sip15DataStartRelativeOffset)
        internal
        pure
        returns (Comparator comparator, address token, bytes32 traitKey, bytes32 expectedTraitValue)
    {
        assembly {
            let sip15DataStartAbsoluteOffset := add(data.offset, sip15DataStartRelativeOffset)
            comparator := shr(248, calldataload(sip15DataStartAbsoluteOffset))
            if gt(comparator, 4) { revert(0, 0) }
            token := shr(96, calldataload(add(sip15DataStartAbsoluteOffset, 0x01)))
            traitKey := calldataload(add(sip15DataStartAbsoluteOffset, 0x15))
            expectedTraitValue := calldataload(add(sip15DataStartAbsoluteOffset, 0x35))
        }
    }

    function decodeSubstandard1(bytes calldata data)
        internal
        pure
        returns (Comparator comparator, address token, bytes32 traitKey, bytes32 expectedTraitValue)
    {
        return decodeSubstandard1(data, 1);
    }

    function decodeSubstandard2(bytes calldata data, uint256 sip15DataStartRelativeOffset)
        internal
        pure
        returns (DynamicTraitRestraint memory)
    {
        return abi.decode(data[sip15DataStartRelativeOffset:], (DynamicTraitRestraint));
    }

    function decodeSubstandard2(bytes calldata data) internal pure returns (DynamicTraitRestraint memory) {
        return decodeSubstandard2(data, 1);
    }

    function decodeSubstandard3(bytes calldata data, uint256 sip15DataStartRelativeOffset)
        internal
        pure
        returns (address token, uint256 traitKeysLength, bytes32 expectedHash)
    {
        assembly {
            let sip15DataStartAbsoluteOffset := add(data.offset, sip15DataStartRelativeOffset)
            token := shr(96, calldataload(sip15DataStartAbsoluteOffset))
            traitKeysLength := calldataload(add(sip15DataStartAbsoluteOffset, 0x14))
            expectedHash := calldataload(add(sip15DataStartAbsoluteOffset, 0x34))
        }
    }

    function decodeSubstandard3(bytes calldata data)
        internal
        pure
        returns (address token, uint256 traitKeysLength, bytes32 expectedHash)
    {
        return decodeSubstandard3(data, 1);
    }
}
