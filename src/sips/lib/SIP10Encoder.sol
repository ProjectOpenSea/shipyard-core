// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SIP10Encoder {
    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 1, which indicates
     *         a transfer activation for a single unminted token.
     *         When using this substandard, the newly minted token should be represented by a single
     *         minimumReceived item.
     *         This method encodes a 0-byte for the substandard version instead of 1 to save on calldata
     *         gas overhead.
     */
    function encodeSubstandard1Efficient() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0));
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 1, which indicates
     *         a transfer activation for a single unminted token.
     *         When using this substandard, the newly minted token should be represented by a single
     *         minimumReceived item.
     */
    function encodeSubstandard1() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(1));
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 2, which
     *         authorizes a transfer for a single specific minted token.
     *         When using this substandard, the minimumReceived array should remain empty.
     * @param tokenId The tokenId to authorize transfer for
     */
    function encodeSubstandard2(uint256 tokenId) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(2), tokenId);
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 3, which
     *         authorizes transfers for multiple specific minted tokens.
     *         When using this substandard, the minimumReceived array should remain empty.
     * @param tokenIds The tokenIds to authorize transfer for
     */
    function encodeSubstandard3(uint256[] memory tokenIds) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(3), abi.encode(tokenIds));
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 4, which
     *         authorizes transfers for multiple unminted tokens.
     *         When using this substandard, the newly minted tokens should be represented by
     *         the included minimumReceived items.
     */
    function encodeSubstandard4() internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(4));
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 5, which
     *         authorizes transfers for multiple arbitrary minted tokens.
     *         When using this substandard, the context represents the number of tokens to transfer.
     *         It does not support "multiple hops," i.e. matching orders (?)
     * @param numTokens The number of tokens to authorize transfer for
     */
    function encodeSubstandard5(uint256 numTokens) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(5), numTokens);
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 6, which
     *         authorizes transfers for multiple unminted token with additional data.
     *         When using this substandard, the unminted tokens should be represented in
     *         the minimumReceived array by a single "synthetic" ERC1155 item with an amount
     *         equal to the number of tokens to mint.
     * @param data The data to be passed to the SIP10 contract
     */
    function encodeSubstandard6(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(6), data);
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 7, which
     *         authorizes transfers for a single unminted token with additional data.
     *         When using this substandard, the unminted token should be represented in the
     *         minimumReceived array
     *
     * @param data The token represented by context
     */
    function encodeSubstandard7(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(7), data);
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 8, which
     *         authorizes transfers for a single minted token with additional data.
     *         When using this substandard, the token should not be represented in the
     *         minimumReceived array
     * @param tokenId The specific token to authorize transfer for
     * @param data Additional data to be passed to the SIP10 contract
     */
    function encodeSubstandard8(uint256 tokenId, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(8), tokenId, data);
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 9, which
     *         authorizes transfers for multiple minted tokens with additional data.
     *         When using this substandard, the authorized tokens should not be represented
     *         in the minimumReceived array.
     * @param tokenIds The specific tokens to authorize transfer for
     * @param data Additional data to be passed to the SIP10 contract
     */
    function encodeSubstandard9(uint256[] memory tokenIds, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(9), abi.encode(tokenIds), data);
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 10, which
     *         authorizes transfers for multiple specific unminted tokens with additional data.
     *         When using this substandard, the unminted tokens should each be represented in the
     *         minimumReceived array
     * @param data Additional data to be passed to the SIP10 contract
     */
    function encodeSubstandard10(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(10), data);
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 11, which
     *         authorizes transfers for multiple arbitrary minted tokens with additional data.
     *         When using this substandard, the context represents the number of tokens to mint.
     *         TODO: NO HOPS????
     * @param numTokens The number of tokens to authorize transfer for
     * @param data Additional data to be passed to the SIP10 contract
     */
    function encodeSubstandard11(uint256 numTokens, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(11), numTokens, data);
    }

    /**
     * @notice Encode extraData for an SIP10 contract that implements substandard 12, which
     *         authorizes transfers for multiple arbitrary unminted tokens with additional data.
     *         When using this substandard, the unminted tokens should be represented in the
     *         minimumReceived array as a single "synthetic" ERC1155 item with the number of tokens
     *         to mint.
     * @param data Additional data to be passed to the SIP10 contract
     */
    function encodeSubstandard12(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(12), data);
    }
}
