// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISIP6} from "./interfaces/sips/ISIP6.sol";
import {Vm} from "forge-std/Test.sol";

library SIP6Decoder {
    error InvalidExtraData();

    function decodeSubstandard0(bytes calldata extraData) internal pure returns (bytes calldata decodedExtraData) {
        return _decodeBytesFromExtraData(extraData, bytes1(0));
    }

    function decodeSubstandard1(bytes calldata extraData, bytes32 expectedHash)
        internal
        pure
        returns (bytes memory decodedExtraData)
    {
        // decode extra data to memory since we need to hash it
        decodedExtraData = _decodeBytesFromExtraData(extraData, bytes1(0x01));
        if (expectedHash != keccak256(decodedExtraData)) {
            revert InvalidExtraData();
        }
    }

    function decodeSubstandard2(bytes calldata extraData, bytes32 expectedHash)
        internal
        pure
        returns (bytes memory decodedFixedData, bytes calldata decodedVariableData)
    {
        _validateVersionByte(extraData, bytes1(0x02));
        uint256 pointerToFixedDataOffset;
        uint256 pointerToVariableDataoffset;
        assembly {
            pointerToFixedDataOffset := add(extraData.offset, 1)
            pointerToVariableDataoffset := add(pointerToFixedDataOffset, 0x20)
        }

        decodedFixedData = _decodeBytesArray(pointerToFixedDataOffset, pointerToFixedDataOffset);
        if (keccak256(decodedFixedData) != expectedHash) {
            revert InvalidExtraData();
        }
        decodedVariableData = _decodeBytesArray(pointerToVariableDataoffset, pointerToFixedDataOffset);
        return (decodedFixedData, decodedVariableData);
    }

    function decodeSubstandard3(bytes calldata extraData)
        internal
        pure
        returns (bytes[] calldata decodedVariableDataArrays)
    {
        return _decodeBytesArraysFromExtraData(extraData, bytes1(0x03));
    }

    function decodeSubstandard4(bytes calldata extraData, bytes32 expectedHash)
        internal
        pure
        returns (bytes[] memory decodedFixedData)
    {
        decodedFixedData = _decodeBytesArraysFromExtraData(extraData, bytes1(0x04));
        _validateFixedArrays(decodedFixedData, expectedHash);

        return decodedFixedData;
    }

    function decodeSubstandard5(bytes calldata extraData, bytes32 expectedHash)
        internal
        pure
        returns (bytes[] memory decodedFixedData, bytes[] calldata decodedVariableData)
    {
        _validateVersionByte(extraData, bytes1(0x05));
        uint256 tupleOffset;
        uint256 pointerToFixedDataOffset;
        uint256 pointerToVariableDataoffset;
        assembly {
            tupleOffset := add(extraData.offset, 1)
            pointerToFixedDataOffset := calldataload(tupleOffset)
            pointerToVariableDataoffset := calldataload(add(tupleOffset, 0x20))
        }
        decodedFixedData = _decodeBytesArrays(pointerToFixedDataOffset, tupleOffset);
        _validateFixedArrays(decodedFixedData, expectedHash);

        decodedVariableData = _decodeBytesArrays(pointerToVariableDataoffset, tupleOffset);

        return (decodedFixedData, decodedVariableData);
    }

    function _validateVersionByte(bytes calldata data, bytes1 expectedVersion) internal pure {
        bytes1 versionByte = data[0];
        if (versionByte != expectedVersion) {
            revert ISIP6.UnsupportedExtraDataVersion(uint8(versionByte));
        }
    }

    function _decodeBytesArray(uint256 pointerToOffset, uint256 relativeStart)
        internal
        pure
        returns (bytes calldata decodedData)
    {
        assembly {
            // the abi-encoded offset of the variable length array starts 1 byte into the calldata. add 1 to account for this.
            let decodedLengthPointer :=
                add(
                    // the offset stored here is relative, not absolute, so add the offset of the offset itself
                    calldataload(pointerToOffset),
                    relativeStart
                )
            decodedData.length := calldataload(decodedLengthPointer)
            decodedData.offset := add(decodedLengthPointer, 0x20)
        }
    }

    function _decodeBytesArrays(uint256 pointerToOffset, uint256 relativeStart)
        internal
        pure
        returns (bytes[] calldata decodedData)
    {
        function(uint256,uint256) internal pure returns (bytes calldata) decodeBytesArray = _decodeBytesArray;
        function(uint256,uint256) internal pure returns (bytes[] calldata) decodeBytesArrays;
        assembly {
            decodeBytesArrays := decodeBytesArray
        }
        return decodeBytesArrays(pointerToOffset, relativeStart);
    }

    function _decodeBytesFromExtraData(bytes calldata data, bytes1 substandard)
        internal
        pure
        returns (bytes calldata decodedData)
    {
        _validateVersionByte(data, substandard);
        uint256 pointerToOffset;
        assembly {
            pointerToOffset := add(data.offset, 1)
        }
        return _decodeBytesArray(pointerToOffset, pointerToOffset);
    }

    function _decodeBytesArraysFromExtraData(bytes calldata data, bytes1 substandard)
        internal
        pure
        returns (bytes[] calldata decodedData)
    {
        _validateVersionByte(data, substandard);
        uint256 pointerToOffset;
        assembly {
            pointerToOffset := add(data.offset, 1)
        }
        return _decodeBytesArrays(pointerToOffset, pointerToOffset);
    }

    function _validateFixedArrays(bytes[] memory fixedArrays, bytes32 expectedHash) internal pure {
        bytes32[] memory hashes = new bytes32[](fixedArrays.length);
        for (uint256 i = 0; i < fixedArrays.length;) {
            hashes[i] = keccak256(fixedArrays[i]);
            unchecked {
                ++i;
            }
        }
        if (keccak256(abi.encodePacked(hashes)) != expectedHash) {
            revert InvalidExtraData();
        }
    }
}
