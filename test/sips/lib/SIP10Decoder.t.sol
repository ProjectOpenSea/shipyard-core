// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SIP10Encoder} from "src/sips/lib/SIP10Encoder.sol";
import {SIP10Decoder} from "src/sips/lib/SIP10Decoder.sol";

contract SIP10DecoderTest is Test {
    function testDecodeSubstandardVersion(uint8 version, bytes memory data) public {
        bytes memory encoded = abi.encodePacked(version, data);
        bytes1 expected = version == 0 ? bytes1(0x01) : bytes1(version);
        assertEq(expected, this.decodeVersion(encoded), "wrong version decoded");
    }

    function testDecode2(uint256 num) public {
        bytes memory data = SIP10Encoder.encodeSubstandard2(num);
        uint256 decoded = this.decode2(data);
        assertEq(decoded, num, "error decoding uint256");
    }

    function testDecode3(uint256[] memory num) public {
        bytes memory data = SIP10Encoder.encodeSubstandard3(num);
        uint256[] memory decoded = this.decode3(data);
        assertEq(keccak256(abi.encode(decoded)), keccak256(abi.encode(num)), "error decoding uint256[]");
    }

    function testDecode5(uint256 num) public {
        bytes memory data = SIP10Encoder.encodeSubstandard5(num);
        uint256 decoded = this.decode5(data);
        assertEq(decoded, num, "error decoding uint256");
    }

    function testDecode6(bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard6(data);
        bytes memory decoded = this.decode6(encoded);
        assertEq(data, decoded, "error decoding bytes");
    }

    function testDecode7(bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard7(data);
        bytes memory decoded = this.decode7(encoded);
        assertEq(data, decoded, "error decoding bytes");
    }

    function testDecode8(uint256 num, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard8(num, data);
        (uint256 decodedNum, bytes memory decodedData) = this.decode8(encoded);
        assertEq(num, decodedNum, "error decoding uint");
        assertEq(data, decodedData, "error decoding packed bytes");
    }

    function testDecode9(uint256[] memory nums, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard9(nums, data);
        (uint256[] memory decodedNums, bytes memory decodedData) = this.decode9(encoded);
        assertEq(keccak256(abi.encode(nums)), keccak256(abi.encode(decodedNums)), "error decoding uint[]");
        assertEq(data, decodedData, "error decoding packed bytes");
    }

    function testDecode10(bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard10(data);
        bytes memory decoded = this.decode10(encoded);
        assertEq(data, decoded);
    }

    function testDecode11(uint256 num, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard11(num, data);
        (uint256 decodedNum, bytes memory decodedData) = this.decode11(encoded);
        assertEq(num, decodedNum, "error decoding uint");
        assertEq(data, decodedData, "error decoding packed bytes");
    }

    function testDecode12(bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard12(data);
        bytes memory decoded = this.decode12(encoded);
        assertEq(data, decoded, "error decoding bytes");
    }

    function testDecodeSubstandardVersion(bytes memory pad, uint8 version, bytes memory data) public {
        bytes memory encoded = abi.encodePacked(pad, version, data);
        bytes1 expected = version == 0 ? bytes1(0x01) : bytes1(version);
        assertEq(expected, this.decodeVersion(encoded, pad.length), "wrong version decoded");
    }

    function testDecode2_(bytes memory pad, uint256 num) public {
        bytes memory data = abi.encodePacked(pad, SIP10Encoder.encodeSubstandard2(num));
        uint256 decoded = this.decode2(data, pad.length + 1);
        assertEq(decoded, num, "error decoding uint256");
    }

    function testDecode3(bytes memory pad, uint256[] memory num) public {
        bytes memory data = SIP10Encoder.encodeSubstandard3(num);
        data = abi.encodePacked(pad, data);
        uint256[] memory decoded = this.decode3(data, pad.length + 1);
        assertEq(keccak256(abi.encode(decoded)), keccak256(abi.encode(num)), "error decoding uint256[]");
    }

    function testDecode5(bytes memory pad, uint256 num) public {
        bytes memory data = SIP10Encoder.encodeSubstandard5(num);
        data = abi.encodePacked(pad, data);
        uint256 decoded = this.decode5(data, pad.length + 1);
        assertEq(decoded, num, "error decoding uint256");
    }

    function testDecode6(bytes memory pad, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard6(data);
        encoded = abi.encodePacked(pad, encoded);
        bytes memory decoded = this.decode6(encoded, pad.length + 1);
        assertEq(data, decoded, "error decoding bytes");
    }

    function testDecode7(bytes memory pad, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard7(data);
        encoded = abi.encodePacked(pad, encoded);
        bytes memory decoded = this.decode7(encoded, pad.length + 1);
        assertEq(data, decoded, "error decoding bytes");
    }

    function testDecode8(bytes memory pad, uint256 num, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard8(num, data);
        encoded = abi.encodePacked(pad, encoded);
        (uint256 decodedNum, bytes memory decodedData) = this.decode8(encoded, pad.length + 1);
        assertEq(num, decodedNum, "error decoding uint");
        assertEq(data, decodedData, "error decoding packed bytes");
    }

    function testDecode9(bytes memory pad, uint256[] memory nums, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard9(nums, data);
        encoded = abi.encodePacked(pad, encoded);
        (uint256[] memory decodedNums, bytes memory decodedData) = this.decode9(encoded, pad.length + 1);
        assertEq(keccak256(abi.encode(nums)), keccak256(abi.encode(decodedNums)), "error decoding uint[]");
        assertEq(data, decodedData, "error decoding packed bytes");
    }

    function testDecode10(bytes memory pad, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard10(data);
        encoded = abi.encodePacked(pad, encoded);

        bytes memory decoded = this.decode10(encoded, pad.length + 1);
        assertEq(data, decoded);
    }

    function testDecode11(bytes memory pad, uint256 num, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard11(num, data);
        encoded = abi.encodePacked(pad, encoded);

        (uint256 decodedNum, bytes memory decodedData) = this.decode11(encoded, pad.length + 1);
        assertEq(num, decodedNum, "error decoding uint");
        assertEq(data, decodedData, "error decoding packed bytes");
    }

    function testDecode12(bytes memory pad, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard12(data);
        encoded = abi.encodePacked(pad, encoded);

        bytes memory decoded = this.decode12(encoded, pad.length + 1);
        assertEq(data, decoded, "error decoding bytes");
    }

    function decodeVersion(bytes calldata data) external pure returns (bytes1) {
        return SIP10Decoder.decodeSubstandardVersion(data);
    }

    function decode2(bytes calldata data) external pure returns (uint256) {
        return SIP10Decoder.decodeSubstandard2(data);
    }

    function decode3(bytes calldata data) external pure returns (uint256[] memory) {
        return SIP10Decoder.decodeSubstandard3(data);
    }

    function decode5(bytes calldata data) external pure returns (uint256) {
        return SIP10Decoder.decodeSubstandard5(data);
    }

    function decode6(bytes calldata data) external pure returns (bytes memory) {
        return SIP10Decoder.decodeSubstandard6(data);
    }

    function decode7(bytes calldata data) external pure returns (bytes memory) {
        return SIP10Decoder.decodeSubstandard7(data);
    }

    function decode8(bytes calldata data) external pure returns (uint256, bytes memory) {
        return SIP10Decoder.decodeSubstandard8(data);
    }

    function decode9(bytes calldata data) external pure returns (uint256[] memory, bytes memory) {
        return SIP10Decoder.decodeSubstandard9(data);
    }

    function decode10(bytes calldata data) external pure returns (bytes memory) {
        return SIP10Decoder.decodeSubstandard10(data);
    }

    function decode11(bytes calldata data) external pure returns (uint256, bytes memory) {
        return SIP10Decoder.decodeSubstandard11(data);
    }

    function decode12(bytes calldata data) external pure returns (bytes memory) {
        return SIP10Decoder.decodeSubstandard12(data);
    }

    function decodeVersion(bytes calldata data, uint256 start) external pure returns (bytes1) {
        return SIP10Decoder.decodeSubstandardVersion(data, start);
    }

    function decode2(bytes calldata data, uint256 start) external pure returns (uint256) {
        return SIP10Decoder.decodeSubstandard2(data, start);
    }

    function decode3(bytes calldata data, uint256 start) external pure returns (uint256[] memory) {
        return SIP10Decoder.decodeSubstandard3(data, start);
    }

    function decode5(bytes calldata data, uint256 start) external pure returns (uint256) {
        return SIP10Decoder.decodeSubstandard5(data, start);
    }

    function decode6(bytes calldata data, uint256 start) external pure returns (bytes memory) {
        return SIP10Decoder.decodeSubstandard6(data, start);
    }

    function decode7(bytes calldata data, uint256 start) external pure returns (bytes memory) {
        return SIP10Decoder.decodeSubstandard7(data, start);
    }

    function decode8(bytes calldata data, uint256 start) external pure returns (uint256, bytes memory) {
        return SIP10Decoder.decodeSubstandard8(data, start);
    }

    function decode9(bytes calldata data, uint256 start) external pure returns (uint256[] memory, bytes memory) {
        return SIP10Decoder.decodeSubstandard9(data, start);
    }

    function decode10(bytes calldata data, uint256 start) external pure returns (bytes memory) {
        return SIP10Decoder.decodeSubstandard10(data, start);
    }

    function decode11(bytes calldata data, uint256 start) external pure returns (uint256, bytes memory) {
        return SIP10Decoder.decodeSubstandard11(data, start);
    }

    function decode12(bytes calldata data, uint256 start) external pure returns (bytes memory) {
        return SIP10Decoder.decodeSubstandard12(data, start);
    }
}
