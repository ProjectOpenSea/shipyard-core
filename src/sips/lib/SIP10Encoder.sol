// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SIP10Encoder {
    function encodeSubstandard0() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0));
    }

    function encodeSubstandard1(uint256 tokenId) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(1), tokenId);
    }

    function encodeSubstandard2(uint256[] memory tokenIds) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(2), abi.encode(tokenIds));
    }

    function encodeSubstandard3() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(3));
    }

    function encodeSubstandard4(uint256 numTokens) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(4), numTokens);
    }

    function encodeSubstandard5(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(5), data);
    }

    function encodeSubstandard6(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(6), data);
    }

    function encodeSubstandard7(uint256 tokenId, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(7), tokenId, data);
    }

    function encodeSubstandard8(uint256[] memory tokenIds, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(8), abi.encode(tokenIds), data);
    }

    function encodeSubstandard9(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(9), data);
    }

    function encodeSubstandard10(uint256 numTokens, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(10), numTokens, data);
    }

    function encodeSubstandard11(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(11), data);
    }
}
