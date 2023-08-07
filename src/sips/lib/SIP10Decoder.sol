// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SIP10Decoder {
    function getSubstandardVersion(bytes calldata extraData) internal pure returns (bytes1) {
        return extraData[0];
    }

    function getSubstandardVersion(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (bytes1)
    {
        return extraData[sip10DataStartRelativeOffset];
    }

    function decodeSubstandard1(bytes calldata extraData) internal pure returns (uint256 tokenId) {
        return decodeSubstandard1(extraData, 1);
    }

    function decodeSubstandard1(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256 tokenId)
    {
        assembly {
            tokenId := calldataload(add(extradata.offset, sip10DataStartRelativeOffset))
        }
    }

    function decodeSubstandard2(bytes calldata extraData) internal pure returns (uint256[] memory) {
        return decodeSubstandard2(extraData, 1);
    }

    function decodeSubstandard2(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256[] calldata tokenIds)
    {
        assembly {
            let idsRelativeOffsetPointer := add(extraData.offset, sip10DataStartRelativeOffset)
            let idsAbsolutePointer := add(calldataload(idsRelativeOffsetPointer), idsRelativeOffsetPointer)
            tokenIds.length := calldataload(idsAbsolutePointer)
            tokenIds.offset := add(idsAbsolutePointer, 0x20)
        }
    }

    function decodeSubstandard4(bytes calldata extraData) internal pure returns (uint256) {
        return decodeSubstandard1(extraData, 1);
    }

    function decodeSubstandard4(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256)
    {
        return decodeSubstandard1(1, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard5(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (bytes calldata data)
    {
        assembly {
            data.length := sub(extraData.length, sip10DataStartRelativeOffset)
            data.offset := add(extraData.offset, sip10DataStartRelativeOffset)
        }
        return data;
    }

    function decodeSubstandard5(bytes calldata extraData) internal pure returns (bytes calldata data) {
        return decodeSubstandard5(extraData, 1);
    }

    function decodeSubstandard6(bytes calldata extraData) internal pure returns (bytes calldata data) {
        return decodeSubstandard5(extraData, 1);
    }

    function decodeSubstandard6(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (bytes calldata data)
    {
        return decodeSubstandard5(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard7(bytes calldata extraData)
        internal
        pure
        returns (uint256 tokenId, bytes calldata data)
    {
        return decodeSubstandard7(extraData, 1);
    }

    function decodeSubstandard7(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256 tokenId, bytes calldata data)
    {
        assembly {
            tokenId := calldataload(add(extraData.offset, sip10DataStartRelativeOffset))
            let dataStartRelativeOffset := add(sip10DataStartRelativeOffset, 0x20)
            data.offset := add(extraData.offset, dataStartRelativeOffset)
            data.length := sub(extraData.length, dataStartRelativeOffset)
        }
    }

    function decodeSubstandard8(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256[] calldata tokenIds, bytes calldata data)
    {
        assembly {
            let tokenIdsOffsetPointer := add(extraData.offset, sip10DataStartRelativeOffset)
            let tokenIdsLengthAbsoluteOffset := add(calldataload(tokenIdsOffsetPointer), tokenIdsOffsetPointer)
            tokenIds.length := calldataload(tokenIdsLengthAbsoluteOffset)
            tokenIds.offset := add(tokenIdsLengthAbsoluteOffset, 0x20)
            data.offset := add(tokenIdsLengthAbsoluteOffset, add(tokenIds.offset, shl(5, tokenIds.length)))
            data.length := sub(extraData.length, data.offset)
        }
    }

    function decodeSubstandard8(bytes calldata extraData)
        internal
        pure
        returns (uint256[] calldata tokenIds, bytes calldata data)
    {
        return decodeSubstandard8(extraData, 1);
    }

    function decodeSubstandard9(bytes calldata extraData) internal pure returns (bytes calldata) {
        return decodeSubstandard6(extraData, 1);
    }

    function decodeSubstandard9(bytes calldata extraData, uint256 sip10RelativeOffsetPointer)
        internal
        pure
        returns (bytes calldata)
    {
        return decodeSubstandard9(extraData, sip10RelativeOffsetPointer);
    }

    function decodeSubstandard10(bytes calldata extraData)
        internal
        pure
        returns (uint256 numTokens, bytes calldata data)
    {
        return decodeSubstandard7(extraData, 1);
    }

    function decodeSubstandard10(bytes calldata extraData, uint256 sip10RelativeOffsetPointer)
        internal
        pure
        returns (uint256 numTokens, bytes calldata data)
    {
        return decodeSubstandard7(extraData, sip10RelativeOffsetPointer);
    }

    function decodeSubstandard11(bytes calldata extraData) internal pure returns (bytes calldata data) {
        return decodeSubstandard1(extraData, 1);
    }

    function decodeSubstandard11(bytes calldata extraData, uint256 sip10RelativeOffsetPointer)
        internal
        pure
        returns (bytes calldata data)
    {
        return decodeSubstandard1(extraData, sip10RelativeOffsetPointer);
    }
}
