// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISIP6} from "./interfaces/sips/ISIP6.sol";

library SIP6Decoder {
    error InvalidExtraData();

    function decodeSubstandard0(bytes calldata extraData) internal pure returns (bytes calldata decodedExtraData) {
        return _decodeBytesFromExtraData(extraData, bytes1(0));
    }

    function decodeSubstandard1(bytes calldata extraData, bytes32 expectedFixedDatahash)
        internal
        pure
        returns (bytes memory decodedExtraData)
    {
        // decode extra data to memory since we need to hash it
        decodedExtraData = _decodeBytesFromExtraData(extraData, bytes1(0x01));
        if (expectedFixedDatahash != keccak256(decodedExtraData)) {
            revert InvalidExtraData();
        }
    }

    function decodeSubstandard2(bytes calldata extraData, bytes32 expectedFixedDatahash)
        internal
        pure
        returns (bytes memory decodedFixedData, bytes calldata decodedVariableData)
    {
        _validateVersionByte(extraData, bytes1(0x02));
        uint256 pointerToFixedDataOffset;
        uint256 pointerToVariableDataoffset;
        ///@solidity memory-safe-assembly
        assembly {
            pointerToFixedDataOffset := add(extraData.offset, 1)
            pointerToVariableDataoffset := add(pointerToFixedDataOffset, 0x20)
        }

        decodedFixedData = _decodeBytesArray(pointerToFixedDataOffset, pointerToFixedDataOffset);
        if (keccak256(decodedFixedData) != expectedFixedDatahash) {
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

    function decodeSubstandard4(bytes calldata extraData, bytes32 expectedFixedDatahash)
        internal
        pure
        returns (bytes[] memory decodedFixedData)
    {
        decodedFixedData = _decodeBytesArraysFromExtraData(extraData, bytes1(0x04));
        _validateFixedArrays(decodedFixedData, expectedFixedDatahash);

        return decodedFixedData;
    }

    function decodeSubstandard5(bytes calldata extraData, bytes32 expectedFixedDatahash)
        internal
        pure
        returns (bytes[] memory decodedFixedData, bytes[] calldata decodedVariableData)
    {
        _validateVersionByte(extraData, bytes1(0x05));
        uint256 pointerToFixedDataOffset;
        uint256 pointerToVariableDataoffset;
        ///@solidity memory-safe-assembly
        assembly {
            pointerToFixedDataOffset := add(extraData.offset, 1)
            pointerToVariableDataoffset := add(pointerToFixedDataOffset, 0x20)
        }
        decodedFixedData = _decodeBytesArrays(pointerToFixedDataOffset, pointerToFixedDataOffset);
        _validateFixedArrays(decodedFixedData, expectedFixedDatahash);

        decodedVariableData = _decodeBytesArrays(pointerToVariableDataoffset, pointerToFixedDataOffset);

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
        ///@solidity memory-safe-assembly
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
        ///@solidity memory-safe-assembly
        assembly {
            decodeBytesArrays := decodeBytesArray
        }
        return decodeBytesArrays(pointerToOffset, relativeStart);
    }

    /**
     * @dev Validate the version byte of extraData and return the contained bytes array.
     * @param data bytes calldata
     * @param substandard version byte of the expected SIP6 substandard
     */
    function _decodeBytesFromExtraData(bytes calldata data, bytes1 substandard)
        internal
        pure
        returns (bytes calldata decodedData)
    {
        _validateVersionByte(data, substandard);
        uint256 pointerToOffset;
        ///@solidity memory-safe-assembly
        assembly {
            pointerToOffset := add(data.offset, 1)
        }
        return _decodeBytesArray(pointerToOffset, pointerToOffset);
    }

    /**
     * @dev Validate the version byte of extraData and return the contained bytes arrays.
     * @param data bytes calldata
     * @param substandard version byte of the expected SIP6 substandard
     */
    function _decodeBytesArraysFromExtraData(bytes calldata data, bytes1 substandard)
        internal
        pure
        returns (bytes[] calldata decodedData)
    {
        _validateVersionByte(data, substandard);
        uint256 pointerToOffset;
        ///@solidity memory-safe-assembly
        assembly {
            pointerToOffset := add(data.offset, 1)
        }
        return _decodeBytesArrays(pointerToOffset, pointerToOffset);
    }

    function _validateFixedArrays(bytes[] memory fixedArrays, bytes32 expectedFixedDatahash) internal pure {
        bytes32[] memory hashes = new bytes32[](fixedArrays.length);
        uint256 fixedArraysLength = fixedArrays.length;
        for (uint256 i = 0; i < fixedArraysLength;) {
            bytes memory fixedArray = fixedArrays[i];
            bytes32 hash;
            ///@solidity memory-safe-assembly
            assembly {
                hash := keccak256(add(fixedArray, 0x20), mload(fixedArray))
            }
            hashes[i] = hash;
            unchecked {
                ++i;
            }
        }
        bytes32 compositeHash;
        ///@solidity memory-safe-assembly
        assembly {
            compositeHash := keccak256(add(hashes, 0x20), shl(5, mload(hashes)))
        }
        if (compositeHash != expectedFixedDatahash) {
            revert InvalidExtraData();
        }
    }
}
