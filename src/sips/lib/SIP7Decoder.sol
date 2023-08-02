// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SIP7Decoder {
    function getVersionByte(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (bytes1)
    {
        return extraData[sip7DataStartRelativeOffset];
    }

    function decodeSubstandard0(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (uint256)
    {
        return abi.decode(extraData[sip7DataStartRelativeOffset:], (uint256));
    }

    function decodeSubstandard1(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (uint8, address, uint256, uint256, address)
    {
        return abi.decode(extraData[sip7DataStartRelativeOffset:], (uint8, address, uint256, uint256, address));
    }

    function decodeSubstandard2(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (bytes32)
    {
        return abi.decode(extraData[sip7DataStartRelativeOffset:], (bytes32));
    }

    function decodeSubstandard3(bytes calldata extraData, uint256 sip7DataStartRelativeOffset)
        internal
        pure
        returns (bytes32[] memory)
    {
        return abi.decode(extraData[sip7DataStartRelativeOffset:], (bytes32[]));
    }
}
