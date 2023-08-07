// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library BaseSIPDecoder {
    function decodeSubstandardVersion(bytes calldata extraData) internal pure returns (bytes1 versionByte) {
        return decodeSubstandardVersion(extraData, 0);
    }

    function decodeSubstandardVersion(bytes calldata extraData, uint256 sipDataStartRelativeOffset)
        internal
        pure
        returns (bytes1 versionByte)
    {
        assembly {
            versionByte := shr(248, calldataload(add(extraData.offset, sipDataStartRelativeOffset)))
            versionByte := or(versionByte, iszero(versionByte))
            versionByte := shl(248, versionByte)
        }
    }

    function decodeUint(bytes calldata extraData) internal pure returns (uint256 val) {
        return decodeUint(extraData, 1);
    }

    function decodeUint(bytes calldata extraData, uint256 sipDataStartRelativeOffset)
        internal
        pure
        returns (uint256 val)
    {
        assembly {
            val := calldataload(add(extraData.offset, sipDataStartRelativeOffset))
        }
    }

    function decodeBytes32(bytes calldata extraData) internal pure returns (bytes32 val) {
        return decodeBytes32(extraData, 1);
    }

    function decodeBytes32(bytes calldata extraData, uint256 sipDataStartRelativeOffset)
        internal
        pure
        returns (bytes32 val)
    {
        assembly {
            val := calldataload(add(extraData.offset, sipDataStartRelativeOffset))
        }
    }

    function decodeUintArray(bytes calldata extraData) internal pure returns (uint256[] calldata) {
        return decodeUintArray(extraData, 1);
    }

    function decodeUintArray(bytes calldata extraData, uint256 sipDataStartRelativeOffset)
        internal
        pure
        returns (uint256[] calldata tokenIds)
    {
        assembly {
            let idsRelativeOffsetPointer := add(extraData.offset, sipDataStartRelativeOffset)
            let idsAbsolutePointer := add(calldataload(idsRelativeOffsetPointer), idsRelativeOffsetPointer)
            tokenIds.length := calldataload(idsAbsolutePointer)
            tokenIds.offset := add(idsAbsolutePointer, 0x20)
        }
    }

    function decodeBytes32Array(bytes calldata extraData) internal pure returns (bytes32[] calldata) {
        return decodeBytes32Array(extraData, 1);
    }

    function decodeBytes32Array(bytes calldata extraData, uint256 sipDataStartRelativeOffset)
        internal
        pure
        returns (bytes32[] calldata tokenIds)
    {
        assembly {
            let idsRelativeOffsetPointer := add(extraData.offset, sipDataStartRelativeOffset)
            let idsAbsolutePointer := add(calldataload(idsRelativeOffsetPointer), idsRelativeOffsetPointer)
            tokenIds.length := calldataload(idsAbsolutePointer)
            tokenIds.offset := add(idsAbsolutePointer, 0x20)
        }
    }

    function decodePackedBytes(bytes calldata extraData, uint256 sipDataStartRelativeOffset)
        internal
        pure
        returns (bytes calldata data)
    {
        assembly {
            data.length := sub(extraData.length, sipDataStartRelativeOffset)
            data.offset := add(extraData.offset, sipDataStartRelativeOffset)
        }
        return data;
    }

    function decodePackedBytes(bytes calldata extraData) internal pure returns (bytes calldata data) {
        return decodePackedBytes(extraData, 1);
    }

    function decodeUintAndBytes(bytes calldata extraData)
        internal
        pure
        returns (uint256 tokenId, bytes calldata data)
    {
        return decodeUintAndBytes(extraData, 1);
    }

    function decodeUintAndBytes(bytes calldata extraData, uint256 sipDataStartRelativeOffset)
        internal
        pure
        returns (uint256 tokenId, bytes calldata data)
    {
        assembly {
            tokenId := calldataload(add(extraData.offset, sipDataStartRelativeOffset))
            let dataStartRelativeOffset := add(sipDataStartRelativeOffset, 0x20)
            data.offset := add(extraData.offset, dataStartRelativeOffset)
            data.length := sub(extraData.length, dataStartRelativeOffset)
        }
    }

    function decodeUintArrayAndBytes(bytes calldata extraData, uint256 sipDataStartRelativeOffset)
        internal
        pure
        returns (uint256[] calldata tokenIds, bytes calldata data)
    {
        assembly {
            let tokenIdsOffsetPointer := add(extraData.offset, sipDataStartRelativeOffset)
            let tokenIdsLengthAbsoluteOffset := add(calldataload(tokenIdsOffsetPointer), tokenIdsOffsetPointer)
            tokenIds.length := calldataload(tokenIdsLengthAbsoluteOffset)
            tokenIds.offset := add(tokenIdsLengthAbsoluteOffset, 0x20)
            data.offset := add(tokenIdsLengthAbsoluteOffset, add(tokenIds.offset, shl(5, tokenIds.length)))
            data.length := sub(extraData.length, data.offset)
        }
    }

    function decodeUintArrayAndBytes(bytes calldata extraData)
        internal
        pure
        returns (uint256[] calldata tokenIds, bytes calldata data)
    {
        return decodeUintArrayAndBytes(extraData, 1);
    }
}
