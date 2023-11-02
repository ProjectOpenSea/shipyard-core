// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {BaseSIPDecoder} from "./BaseSIPDecoder.sol";

library SIP7Decoder {
    function decodeSubstandardVersion(bytes calldata extraData) internal pure returns (bytes1) {
        return BaseSIPDecoder.decodeSubstandardVersion(extraData);
    }

    function decodeSubstandardVersion(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (bytes1)
    {
        return BaseSIPDecoder.decodeSubstandardVersion(extraData, sip7DataStartRelativeOffset);
    }

    function decodeSubstandard1(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (uint256)
    {
        return BaseSIPDecoder.decodeUint(extraData, sip7DataStartRelativeOffset);
    }

    function decodeSubstandard1(bytes calldata extraData) internal pure returns (uint256) {
        return BaseSIPDecoder.decodeUint(extraData);
    }

    function decodeSubstandard2(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (ItemType, address, uint256, uint256, address)
    {
        return abi.decode(extraData[sip7DataStartRelativeOffset:], (ItemType, address, uint256, uint256, address));
    }

    function decodeSubstandard2(bytes calldata extraData)
        internal
        pure
        returns (ItemType, address, uint256, uint256, address)
    {
        return decodeSubstandard2(extraData, 1);
    }

    function decodeSubstandard3(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (bytes32)
    {
        return BaseSIPDecoder.decodeBytes32(extraData, sip7DataStartRelativeOffset);
    }

    function decodeSubstandard3(bytes calldata extraData) internal pure returns (bytes32) {
        return BaseSIPDecoder.decodeBytes32(extraData);
    }

    function decodeSubstandard4(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (bytes32[] memory)
    {
        return BaseSIPDecoder.decodeBytes32Array(extraData, sip7DataStartRelativeOffset);
    }

    function decodeSubstandard4(bytes calldata extraData) internal pure returns (bytes32[] memory) {
        return BaseSIPDecoder.decodeBytes32Array(extraData);
    }
}
