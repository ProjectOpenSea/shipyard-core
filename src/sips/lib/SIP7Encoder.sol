// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReceivedItem} from "seaport-types/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/lib/ConsiderationEnums.sol";

library SIP7Encoder {
    /**
     * @notice Encode extraData for SIP7-substandard-1, which specifies the
     *         required identifier of the first ReceivedItem
     * @param identifier Required identifier of first returned ReceivedItem
     */
    function encodeSubstandard1(uint256 identifier) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(1), identifier);
    }

    /**
     * @notice Encode extraData for SIP7-substandard-1, which specifies the
     *         required identifier of the first ReceivedItem. Uses a 0-byte
     *         for version instead of 1 to save calldata gas overhead.
     * @param identifier Required identifier of first returned ReceivedItem
     */
    function encodeSubstandard1Efficient(uint256 identifier) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0), identifier);
    }

    /**
     * @notice Encode extraData for SIP7-substandard-1, which specifies a required considerationItem
     *         is present on an order
     * @param itemType The Seaport ItemType of the required tip
     * @param token The address of the token to be tipped
     * @param identifier The identifier of the tip
     * @param amount The amount of the tip
     * @param recipient The address of the recipient of the tip
     */
    function encodeSubstandard2(ItemType itemType, address token, uint256 identifier, uint256 amount, address recipient)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(uint8(2), abi.encode(itemType, token, identifier, amount, recipient));
    }

    /**
     * @notice Encode extraData for SIP7-substandard-1, which specifies a required
     *         considerationItem is present on an order
     * @param item The considerationItem to encode
     */
    function encodeSubstandard2(ReceivedItem memory item) internal pure returns (bytes memory) {
        return encodeSubstandard2(item.itemType, item.token, item.identifier, item.amount, item.recipient);
    }

    /**
     * @notice Encode extraData for SIP7-substandard-2, which specifies a hash that the hash of
     *         the receivedItems array must match
     * @param receivedItemsHash The hash of the receivedItems array
     */
    function encodeSubstandard3(bytes32 receivedItemsHash) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(3), receivedItemsHash);
    }

    /**
     * @notice Encode extraData for SIP7-substandard-3, which specifies a list of orderHashes
     *         that are forbidden from being included in the same fulfillment
     * @param forbiddenOrderHashes The list of forbidden orderHashes
     */
    function encodeSubstandard4(bytes32[] memory forbiddenOrderHashes) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(4), abi.encode(forbiddenOrderHashes));
    }
}
