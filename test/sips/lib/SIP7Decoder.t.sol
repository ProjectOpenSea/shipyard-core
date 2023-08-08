// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SIP7Decoder} from "shipyard-core/sips/lib/SIP7Decoder.sol";
import {SIP7Encoder} from "shipyard-core/sips/lib/SIP7Encoder.sol";
import {ItemType} from "seaport-types/lib/ConsiderationEnums.sol";

contract SIP7DecoderTest is Test {
    struct ReceivedItemRaw {
        uint8 itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address recipient;
    }

    function testDecodeSubstandard1(uint256 num) public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard1(num);
        uint256 result = this.decode1(encoded);
        assertEq(result, num);
    }

    function testDecodeSubstandard2(
        uint8 itemType_,
        address _token,
        uint256 _identifier,
        uint256 _amount,
        address _recipient
    ) public {
        ItemType _itemType = ItemType(uint8(bound(itemType_, 0, 5)));
        bytes memory encoded = SIP7Encoder.encodeSubstandard2(_itemType, _token, _identifier, _amount, _recipient);
        (ItemType itemType, address token, uint256 identifier, uint256 amount, address recipient) =
            this.decode2(encoded);
        assertEq(uint256(itemType), uint8(_itemType), "incorrect itemType");
        assertEq(token, _token, "incorrect token");
        assertEq(identifier, _identifier, "incorrect identifier");
        assertEq(amount, _amount, "incorrect amount");
        assertEq(recipient, _recipient, "incorrect recipient");
    }

    function testDecodeSubstandard3(bytes32 num) public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard3(num);
        bytes32 result = this.decode3(encoded);
        assertEq(result, num);
    }

    function testDecodeSubstandard4(bytes32[] memory hashes) public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard4(hashes);
        bytes32[] memory result = this.decode4(encoded);
        assertEq(result.length, hashes.length);
        for (uint256 i; i < hashes.length; i++) {
            assertEq(result[i], hashes[i], "hashes[i] incorrect");
        }
    }

    function testDecodeSubstandard1(bytes memory pad, uint256 num) public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard1(num);
        encoded = abi.encodePacked(pad, encoded);
        uint256 result = this.decode1(encoded, pad.length + 1);
        assertEq(result, num);
    }

    function testDecodeSubstandard2(bytes memory pad, ReceivedItemRaw memory item) public {
        ItemType _itemType = ItemType(uint8(bound(item.itemType, 0, 5)));
        bytes memory encoded =
            SIP7Encoder.encodeSubstandard2(_itemType, item.token, item.identifier, item.amount, item.recipient);
        encoded = abi.encodePacked(pad, encoded);
        (ItemType itemType, address token, uint256 identifier, uint256 amount, address recipient) =
            this.decode2(encoded, pad.length + 1);
        assertEq(uint256(itemType), uint8(_itemType), "incorrect itemType");
        assertEq(token, item.token, "incorrect token");
        assertEq(identifier, item.identifier, "incorrect identifier");
        assertEq(amount, item.amount, "incorrect amount");
        assertEq(recipient, item.recipient, "incorrect recipient");
    }

    function testDecodeSubstandard3(bytes memory pad, bytes32 num) public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard3(num);
        encoded = abi.encodePacked(pad, encoded);
        bytes32 result = this.decode3(encoded, pad.length + 1);
        assertEq(result, num);
    }

    function testDecodeSubstandard4(bytes memory pad, bytes32[] memory hashes) public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard4(hashes);
        encoded = abi.encodePacked(pad, encoded);
        bytes32[] memory result = this.decode4(encoded, pad.length + 1);
        assertEq(result.length, hashes.length);
        for (uint256 i; i < hashes.length; i++) {
            assertEq(result[i], hashes[i], "hashes[i] incorrect");
        }
    }

    function decode1(bytes calldata extraData) external pure returns (uint256) {
        return SIP7Decoder.decodeSubstandard1(extraData);
    }

    function decode2(bytes calldata extraData) external pure returns (ItemType, address, uint256, uint256, address) {
        return SIP7Decoder.decodeSubstandard2(extraData);
    }

    function decode3(bytes calldata extraData) external pure returns (bytes32) {
        return SIP7Decoder.decodeSubstandard3(extraData);
    }

    function decode4(bytes calldata extraData) external pure returns (bytes32[] memory) {
        return SIP7Decoder.decodeSubstandard4(extraData);
    }

    function decode1(bytes calldata extraData, uint256 start) external pure returns (uint256) {
        return SIP7Decoder.decodeSubstandard1(extraData, start);
    }

    function decode2(bytes calldata extraData, uint256 start)
        external
        pure
        returns (ItemType, address, uint256, uint256, address)
    {
        return SIP7Decoder.decodeSubstandard2(extraData, start);
    }

    function decode3(bytes calldata extraData, uint256 start) external pure returns (bytes32) {
        return SIP7Decoder.decodeSubstandard3(extraData, start);
    }

    function decode4(bytes calldata extraData, uint256 start) external pure returns (bytes32[] memory) {
        return SIP7Decoder.decodeSubstandard4(extraData, start);
    }
}
