// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SIP10Encoder {
    function encodeSubstandard1Efficient() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0));
    }

    function encodeSubstandard1() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(1));
    }

    function encodeSubstandard2(uint256 tokenId) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(2), tokenId);
    }

    function encodeSubstandard3(uint256[] memory tokenIds) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(3), abi.encode(tokenIds));
    }

    function encodeSubstandard4() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(4));
    }

    function encodeSubstandard5(uint256 numTokens) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(5), numTokens);
    }

    function encodeSubstandard6(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(6), data);
    }

    function encodeSubstandard7(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(7), data);
    }

    function encodeSubstandard8(uint256 tokenId, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(8), tokenId, data);
    }

    function encodeSubstandard9(uint256[] memory tokenIds, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(9), abi.encode(tokenIds), data);
    }

    function encodeSubstandard10(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(10), data);
    }

    function encodeSubstandard11(uint256 numTokens, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(11), numTokens, data);
    }

    function encodeSubstandard12(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(12), data);
    }
}
