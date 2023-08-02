// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISIP6} from "shipyard-core/interfaces/sips/ISIP6.sol";

library SIP6Decoder {
    // bytes4(keccak256("InvalidExtraDataEncoding(uint8)")
    uint256 constant INVALID_EXTRA_DATA_ENCODING_SELECTOR = 0xdefb1057;
    uint256 constant SELECTOR_MEMORY_OFFSET = 0x1c;
    uint256 constant _32_BIT_MASK = 0xffffffff;

    error InvalidExtraData();

    /**
     * @notice Read the SIP6 substandard version byte from the extraData field of a SIP6 bytes array.
     * @param extraData bytes calldata
     */
    function getSubstandardVersion(bytes calldata extraData) internal pure returns (bytes1 substandard) {
        return extraData[0];
    }

    /**
     * @notice Decode an SIP6-Substandard-0 extraData field. It should consist of a single byte 0x00 followed by a "variable" bytes array.
     *         No validation is performed on the variable bytes array.
     *         The expected encoding is the equivalent of `abi.encodePacked(uint8(0x00), variableData)`.
     * @param extraData bytes calldata
     */
    function decodeSubstandard0(bytes calldata extraData) internal pure returns (bytes calldata decodedExtraData) {
        return _decodePackedBytesArrayFromExtraData(extraData, bytes1(0));
    }

    /**
     * @notice Decode an SIP6-Substandard-1 extraData field. It should consist of a single byte 0x01 followed by a "fixed" bytes array,
     *         the keccak256 hash of the packed bytes array (eg, `keccak256(abi.encodePacked(extraData))`) should match the
     *         expectedFixedDataHash parameter.
     *         The expected encoding is the equivalent of `abi.encodePacked(uint8(0x01), fixedData)`.
     * @param extraData bytes calldata
     * @param expectedFixedDataHash Expected hash of the fixed bytes array
     */
    function decodeSubstandard1(bytes calldata extraData, bytes32 expectedFixedDataHash)
        internal
        pure
        returns (bytes memory decodedExtraData)
    {
        return _decodeBytesPackedFromExtraDataAndValidateExpectedHash(extraData, bytes1(0x01), expectedFixedDataHash);
    }

    /**
     * @notice Decode an SIP6-Substandard-2 extraData field. It should consist of a single byte 0x02 followed by a "fixed" bytes array,
     *         followed by a "variable" bytes array. The keccak256 hash of the "fixed" bytes array must match the expectedFixedDataHash parameter.
     *         No validation is performed on the "variable" bytes array.
     *         The expected encoding is the equivalent of `abi.encodePacked(uint8(0x02), abi.encode(fixedData, variableData))`.
     * @param extraData bytes calldata
     * @param expectedFixedDataHash Expected hash of the fixed bytes array.
     * @return decodedFixedData
     * @return decodedVariableData
     */
    function decodeSubstandard2(bytes calldata extraData, bytes32 expectedFixedDataHash)
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

        decodedFixedData = _decodeBytesArrayAndValidateExpectedHash(
            pointerToFixedDataOffset, pointerToFixedDataOffset, expectedFixedDataHash
        );
        decodedVariableData = _decodeBytesArray(pointerToVariableDataoffset, pointerToFixedDataOffset);
        return (decodedFixedData, decodedVariableData);
    }

    /**
     * @notice Decode an SIP6-Substandard-3 extraData field. It should consist of a single byte 0x03 followed by an array of "variable" bytes arrays.
     *         No validation is performed on the "variable" bytes arrays.
     *         The expected encoding is the equivalent of `abi.encodePacked(uint8(0x03), abi.encode(variableDataArrays))`.
     * @param extraData bytes calldata
     */
    function decodeSubstandard3(bytes calldata extraData)
        internal
        pure
        returns (bytes[] calldata decodedVariableDataArrays)
    {
        return _decodeBytesArraysFromExtraData(extraData, bytes1(0x03));
    }

    /**
     * @notice Decode an SIP6-Substandard-4 extraData field. It should consist of a single byte 0x04 followed by an array of "fixed" bytes arrays.
     *         The keccak256 hash of the hashes of all "fixed" bytes arrays must match the expectedFixedDataHash parameter. The expected hash must
     *         be the equivalent of `keccak256(abi.encodePacked(keccak256(fixedData1), keccak256(fixedData2), ...))`.
     *         The expected encoding is the equivalent of `abi.encodePacked(uint8(0x04), abi.encode(fixedDataArrays))`.
     * @param extraData bytes calldata
     * @param expectedFixedDataHash The expected hash of the fixed bytes array.
     */
    function decodeSubstandard4(bytes calldata extraData, bytes32 expectedFixedDataHash)
        internal
        pure
        returns (bytes[] memory decodedFixedData)
    {
        decodedFixedData = _decodeBytesArraysFromExtraData(extraData, bytes1(0x04));
        _validateFixedArrays(decodedFixedData, expectedFixedDataHash);

        return decodedFixedData;
    }

    /**
     * @notice Decode an SIP6-Substandard-5 extraData field. It should consist of a single byte 0x05 followed by an array of "fixed" bytes arrays,
     *         followed by an array of "variable" bytes arrays. The keccak256 hash of the hashes of all "fixed" bytes arrays must match the
     *         expectedFixedDataHash parameter. The expected hash must be the equivalent of `keccak256(abi.encodePacked(keccak256(fixedData1),
     *         keccak256(fixedData2), ...))`.
     *         No validation is performed on the "variable" bytes arrays.
     *         The expected encoding is the equivalent of `abi.encodePacked(uint8(0x05), abi.encode(fixedDataArrays, variableDataArrays))`.
     * @param extraData bytes calldata
     * @param expectedFixedDataHash The expected hash of the fixed bytes array.
     * @return decodedFixedData
     * @return decodedVariableData
     */
    function decodeSubstandard5(bytes calldata extraData, bytes32 expectedFixedDataHash)
        internal
        pure
        returns (bytes[] memory decodedFixedData, bytes[] calldata decodedVariableData)
    {
        _validateVersionByte(extraData, bytes1(0x05));
        uint256 pointerToFixedDataOffset;
        uint256 pointerToVariableDataoffset;

        assembly {
            pointerToFixedDataOffset := add(extraData.offset, 1)
            pointerToVariableDataoffset := add(pointerToFixedDataOffset, 0x20)
        }
        decodedFixedData = _decodeBytesArrays(pointerToFixedDataOffset, pointerToFixedDataOffset);
        _validateFixedArrays(decodedFixedData, expectedFixedDataHash);

        decodedVariableData = _decodeBytesArrays(pointerToVariableDataoffset, pointerToFixedDataOffset);

        return (decodedFixedData, decodedVariableData);
    }

    /**
     * @dev Load the first byte of the extraData and validate that it matches the expected version byte.
     * @param data bytes calldata
     * @param expectedVersion Expected SIP6 substandard version byte
     */
    function _validateVersionByte(bytes calldata data, bytes1 expectedVersion) internal pure {
        bytes1 versionByte = data[0];
        if (versionByte != expectedVersion) {
            revert ISIP6.UnsupportedExtraDataVersion(uint8(versionByte));
        }
    }

    function _decodePackedBytesArray(bytes calldata data, uint256 absoluteStart)
        internal
        pure
        returns (bytes calldata decoded)
    {
        assembly {
            decoded.length := sub(data.length, 1)
            decoded.offset := absoluteStart
        }
        return decoded;
    }

    /**
     * @dev Derive a bytes calldata array from SIP6 encoded extraData. Calculates the offset of the array in calldata, loads its length, and places
     *      both values onto the stack as a `bytes calldata` type.
     */
    function _decodeBytesArray(uint256 pointerToRelativeOffset, uint256 absoluteStart)
        internal
        pure
        returns (bytes calldata decodedData)
    {
        assembly {
            // the abi-encoded offset of the variable length array starts 1 byte into the calldata. add 1 to account for this.
            let decodedLengthPointer :=
                and(
                    add(
                        // the offset stored here is relative, not absolute, so add the offset of the offset itself
                        calldataload(pointerToRelativeOffset),
                        absoluteStart
                    ),
                    _32_BIT_MASK
                )
            decodedData.length := and(calldataload(decodedLengthPointer), _32_BIT_MASK)
            decodedData.offset := add(decodedLengthPointer, 0x20)
        }
    }

    function _decodePackedBytesArrayFromExtraData(bytes calldata data, bytes1 expectedVersion)
        internal
        pure
        returns (bytes calldata decoded)
    {
        _validateVersionByte(data, expectedVersion);
        uint256 pointerToRelativeOffset;
        assembly {
            pointerToRelativeOffset := add(data.offset, 1)
        }
        return _decodePackedBytesArray(data, pointerToRelativeOffset);
    }

    /**
     * @dev Derive a bytes calldata array from SIP6 encoded extraData and validate that its keccak256 hash matches the expected hash.
     */
    function _decodeBytesArrayAndValidateExpectedHash(
        uint256 pointerToRelativeOffset,
        uint256 absoluteStart,
        bytes32 expectedHash
    ) internal pure returns (bytes memory decodedData) {
        decodedData = _decodeBytesArray(pointerToRelativeOffset, absoluteStart);
        if (keccak256(decodedData) != expectedHash) {
            revert InvalidExtraData();
        }
    }

    /**
     * @dev Derive an calldata array of  bytes arrays from SIP6 encoded extraData. Calculates the offset of the array in calldata, loads its length, and places
     *      both values onto the stack as a `bytes[] calldata` type. Re-uses `_decodeBytesArray` by casting the return value to `bytes[] calldata`.
     */
    function _decodeBytesArrays(uint256 pointerToRelativeOffset, uint256 absoluteStart)
        internal
        pure
        returns (bytes[] calldata decodedData)
    {
        function(uint256,uint256) internal pure returns (bytes calldata) decodeBytesArray = _decodeBytesArray;
        function(uint256,uint256) internal pure returns (bytes[] calldata) decodeBytesArrays;

        assembly {
            decodeBytesArrays := decodeBytesArray
        }
        return decodeBytesArrays(pointerToRelativeOffset, absoluteStart);
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
        uint256 pointerToRelativeOffset;

        assembly {
            pointerToRelativeOffset := add(data.offset, 1)
        }
        decodedData = _decodeBytesArray(pointerToRelativeOffset, pointerToRelativeOffset);
        validateBytes(data, decodedData, substandard);
        return decodedData;
    }

    function _decodeBytesPackedFromExtraDataAndValidateExpectedHash(
        bytes calldata data,
        bytes1 substandard,
        bytes32 expectedHash
    ) internal pure returns (bytes memory decodedData) {
        decodedData = _decodePackedBytesArrayFromExtraData(data, substandard);
        if (keccak256(decodedData) != expectedHash) {
            revert InvalidExtraData();
        }
        return decodedData;
    }

    /**
     * @dev Validate the version byte of extraData and return the contained bytes array.
     * @param data bytes calldata
     * @param substandard Expected SIP6 substandard version byte
     * @param expectedHash Expected hash of the bytes array
     */
    function _decodeBytesFromExtraDataAndValidateExpectedHash(
        bytes calldata data,
        bytes1 substandard,
        bytes32 expectedHash
    ) internal pure returns (bytes memory decodedData) {
        _validateVersionByte(data, substandard);
        uint256 pointerToRelativeOffset;

        assembly {
            pointerToRelativeOffset := add(data.offset, 1)
        }
        // copy bytes to memory since they must be hashed
        decodedData =
            _decodeBytesArrayAndValidateExpectedHash(pointerToRelativeOffset, pointerToRelativeOffset, expectedHash);
        return decodedData;
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
        uint256 pointerToRelativeOffset;

        assembly {
            pointerToRelativeOffset := add(data.offset, 1)
        }
        decodedData = _decodeBytesArrays(pointerToRelativeOffset, pointerToRelativeOffset);
        validateArrays(data, decodedData, substandard);
        return decodedData;
    }

    /**
     * @dev Validate that the hash of all array hashes matches the expected hash.
     */
    function _validateFixedArrays(bytes[] memory fixedArrays, bytes32 expectedFixedDataHash) internal pure {
        bytes32[] memory hashes = new bytes32[](fixedArrays.length);
        uint256 fixedArraysLength = fixedArrays.length;
        for (uint256 i = 0; i < fixedArraysLength;) {
            bytes memory fixedArray = fixedArrays[i];
            hashes[i] = keccak256(fixedArray);
            unchecked {
                ++i;
            }
        }
        bytes32 compositeHash;
        ///@solidity memory-safe-assembly
        assembly {
            compositeHash := keccak256(add(hashes, 0x20), shl(5, mload(hashes)))
        }
        if (compositeHash != expectedFixedDataHash) {
            revert InvalidExtraData();
        }
    }

    function validateBytes(bytes calldata extraData, bytes calldata decoded, bytes1 substandard) internal pure {
        uint256 extraDataStartOffset;
        uint256 arrayAbsoluteOffset;
        assembly {
            extraDataStartOffset := extraData.offset
            arrayAbsoluteOffset := decoded.offset
        }
        validateCalldataArray(extraDataStartOffset, extraData.length, arrayAbsoluteOffset, decoded.length, substandard);
    }

    function validateArrays(bytes calldata extraData, bytes[] calldata decoded, bytes1 substandard) internal pure {
        uint256 extraDataStartOffset;
        uint256 arrayAbsoluteOffset;
        assembly {
            extraDataStartOffset := extraData.offset
            arrayAbsoluteOffset := decoded.offset
        }
        validateCalldataArray({
            extraDataOffset: extraDataStartOffset,
            extraDataLength: extraData.length,
            arrayAbsoluteOffset: arrayAbsoluteOffset,
            arrayLengthInBytes: decoded.length << 5,
            substandard: substandard
        });
        for (uint256 i = 0; i < decoded.length;) {
            uint256 subArrayOffset;
            uint256 subArrayLength;
            assembly {
                let subArrayOffsetPointer
                // add decoded.offset absolute offset to the relative offset of the array
                :=
                    add(
                        // mask offset to avoid bad data
                        and(
                            // load relative offset from its position in the array
                            calldataload(
                                // add 32i to the start of the array
                                add(
                                    decoded.offset,
                                    // shl(5,x) == mul(0x20,x)
                                    shl(5, i)
                                )
                            ),
                            _32_BIT_MASK
                        ),
                        decoded.offset
                    )
                subArrayLength
                // mask to avoid bad data
                :=
                    and(
                        // load length from absolute offset of array
                        calldataload(subArrayOffsetPointer),
                        _32_BIT_MASK
                    )
                // add 20 to get the start of data offset
                subArrayOffset := add(subArrayOffsetPointer, 0x20)
            }

            validateCalldataArray({
                extraDataOffset: extraDataStartOffset,
                extraDataLength: extraData.length,
                arrayAbsoluteOffset: subArrayOffset,
                arrayLengthInBytes: subArrayLength,
                substandard: substandard
            });
            unchecked {
                ++i;
            }
        }
    }

    function validateCalldataArray(
        uint256 extraDataOffset,
        uint256 extraDataLength,
        uint256 arrayAbsoluteOffset,
        uint256 arrayLengthInBytes,
        bytes1 substandard
    ) internal pure {
        assembly {
            // TODO: how does this work with pointers to 0-length arrays?
            // check that the length of the array plus its offset is less than the length of the extraData plus its offset,
            // i.e., that no part of the array extends past the end of the extraData
            let errBuff := gt(add(arrayLengthInBytes, arrayAbsoluteOffset), add(extraDataLength, extraDataOffset))
            // check that the array offset is greater than the extraData offset, i.e., that no part of the array is before the start of the extraData
            errBuff := or(errBuff, iszero(gt(arrayAbsoluteOffset, extraDataOffset)))
            //
            if errBuff {
                mstore(0, INVALID_EXTRA_DATA_ENCODING_SELECTOR)
                // since bytes1 are left-aligned, add 0x1f to where we actually want to write it so that the topmost bit is right-aligned
                mstore(0x3f, substandard)
                revert(SELECTOR_MEMORY_OFFSET, 0x24)
            }
        }
    }
}
