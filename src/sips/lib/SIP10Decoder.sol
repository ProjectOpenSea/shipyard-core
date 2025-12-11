// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseSIPDecoder} from "./BaseSIPDecoder.sol";

library SIP10Decoder {
    function decodeSubstandardVersion(bytes calldata extraData) internal pure returns (bytes1) {
        return BaseSIPDecoder.decodeSubstandardVersion(extraData);
    }

    function decodeSubstandardVersion(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (bytes1)
    {
        return BaseSIPDecoder.decodeSubstandardVersion(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard2(bytes calldata extraData) internal pure returns (uint256 tokenId) {
        return BaseSIPDecoder.decodeUint(extraData);
    }

    function decodeSubstandard2(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256 tokenId)
    {
        return BaseSIPDecoder.decodeUint(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard3(bytes calldata extraData) internal pure returns (uint256[] memory) {
        return BaseSIPDecoder.decodeUintArray(extraData);
    }

    function decodeSubstandard3(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256[] calldata tokenIds)
    {
        return BaseSIPDecoder.decodeUintArray(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard5(bytes calldata extraData) internal pure returns (uint256) {
        return BaseSIPDecoder.decodeUint(extraData);
    }

    function decodeSubstandard5(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256)
    {
        return BaseSIPDecoder.decodeUint(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard6(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (bytes calldata data)
    {
        return BaseSIPDecoder.decodePackedBytes(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard6(bytes calldata extraData) internal pure returns (bytes calldata data) {
        return BaseSIPDecoder.decodePackedBytes(extraData);
    }

    function decodeSubstandard7(bytes calldata extraData) internal pure returns (bytes calldata data) {
        return BaseSIPDecoder.decodePackedBytes(extraData);
    }

    function decodeSubstandard7(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (bytes calldata data)
    {
        return BaseSIPDecoder.decodePackedBytes(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard8(bytes calldata extraData) internal pure returns (uint256 tokenId, bytes calldata data) {
        return BaseSIPDecoder.decodeUintAndBytes(extraData);
    }

    function decodeSubstandard8(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256 tokenId, bytes calldata data)
    {
        return BaseSIPDecoder.decodeUintAndBytes(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard9(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256[] calldata tokenIds, bytes calldata data)
    {
        return BaseSIPDecoder.decodeUintArrayAndBytes(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard9(bytes calldata extraData)
        internal
        pure
        returns (uint256[] calldata tokenIds, bytes calldata data)
    {
        return BaseSIPDecoder.decodeUintArrayAndBytes(extraData);
    }

    function decodeSubstandard10(bytes calldata extraData) internal pure returns (bytes calldata) {
        return BaseSIPDecoder.decodePackedBytes(extraData);
    }

    function decodeSubstandard10(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (bytes calldata)
    {
        return BaseSIPDecoder.decodePackedBytes(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard11(bytes calldata extraData)
        internal
        pure
        returns (uint256 numTokens, bytes calldata data)
    {
        return BaseSIPDecoder.decodeUintAndBytes(extraData);
    }

    function decodeSubstandard11(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (uint256 numTokens, bytes calldata data)
    {
        return BaseSIPDecoder.decodeUintAndBytes(extraData, sip10DataStartRelativeOffset);
    }

    function decodeSubstandard12(bytes calldata extraData) internal pure returns (bytes calldata data) {
        return BaseSIPDecoder.decodePackedBytes(extraData);
    }

    function decodeSubstandard12(bytes calldata extraData, uint256 sip10DataStartRelativeOffset)
        internal
        pure
        returns (bytes calldata data)
    {
        return BaseSIPDecoder.decodePackedBytes(extraData, sip10DataStartRelativeOffset);
    }
}
