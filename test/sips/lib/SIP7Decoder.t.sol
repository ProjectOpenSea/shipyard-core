// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SIP7Decoder} from "shipyard-core/sips/lib/SIP7Decoder.sol";
import {SIP7Encoder} from "shipyard-core/sips/lib/SIP7Encoder.sol";
import {ItemType} from "seaport-types/lib/ConsiderationEnums.sol";

contract SIP7DecoderTest is Test {
    function testDecodeSubstandard0() public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard0(1);
        uint256 result = this.decode0(encoded);
        assertEq(result, 1);
    }

    function testDecodeSubstandard1() public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard1(ItemType(1), address(2), 3, 4, address(5));
        (ItemType itemType, address token, uint256 identifier, uint256 amount, address recipient) =
            this.decode1(encoded);
        assertEq(uint256(itemType), 1, "incorrect itemType");
        assertEq(token, address(2), "incorrect token");
        assertEq(identifier, 3, "incorrect identifier");
        assertEq(amount, 4, "incorrect amount");
        assertEq(recipient, address(5), "incorrect recipient");
    }

    function testDecodeSubstandard2() public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard2(bytes32(uint256(1234)));
        bytes32 result = this.decode2(encoded);
        assertEq(result, bytes32(uint256(1234)));
    }

    function testDecodeSubstandard3() public {
        bytes32[] memory hashes = new bytes32[](2);
        hashes[0] = bytes32(uint256(1234));
        hashes[1] = bytes32(uint256(5678));
        bytes memory encoded = SIP7Encoder.encodeSubstandard3(hashes);
        bytes32[] memory result = this.decode3(encoded);
        assertEq(result.length, 2);
        assertEq(result[0], bytes32(uint256(1234)));
        assertEq(result[1], bytes32(uint256(5678)));
    }

    function decode0(bytes calldata extraData) external pure returns (uint256) {
        return SIP7Decoder.decodeSubstandard0(extraData);
    }

    function decode1(bytes calldata extraData) external pure returns (ItemType, address, uint256, uint256, address) {
        return SIP7Decoder.decodeSubstandard1(extraData);
    }

    function decode2(bytes calldata extraData) external pure returns (bytes32) {
        return SIP7Decoder.decodeSubstandard2(extraData);
    }

    function decode3(bytes calldata extraData) external pure returns (bytes32[] memory) {
        return SIP7Decoder.decodeSubstandard3(extraData);
    }
}
