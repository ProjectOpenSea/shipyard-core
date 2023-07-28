// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ISIP6} from "shipyard-core/interfaces/sips/ISIP6.sol";
import {SIP6Decoder} from "shipyard-core/SIP6Decoder.sol";

contract SIP6DecoderTest is Test {
    function testDecode0() public {
        bytes memory variable = "hello world";
        bytes memory extraData = abi.encodePacked(uint8(0), abi.encode(variable));
        bytes memory decoded = this.decode0(extraData);
        assertEq(decoded, variable);
    }

    function testDecode0_weirdOffset() public {
        bytes memory extraData =
            abi.encodePacked(uint8(0), uint256(0x40), uint256(0), uint256(0x20), bytes32("hello world"));
        bytes memory decoded = this.decode0(extraData);
        assertEq(decoded, abi.encode(bytes32("hello world")));
    }

    function testDecode1() public {
        bytes memory fixedData = "hello world";
        bytes32 expectedHash = keccak256(fixedData);
        bytes memory extraData = abi.encodePacked(uint8(1), abi.encode(fixedData), expectedHash);
        bytes memory decoded = this.decode1(extraData, expectedHash);
        assertEq(decoded, fixedData);
    }

    function testDecode2() public {
        bytes memory fixedData = "hello";
        bytes memory variableData = "world";
        bytes32 expectedHash = keccak256(fixedData);
        bytes memory extraData = abi.encodePacked(uint8(2), abi.encode(fixedData, variableData));
        (bytes memory decodedFixedData, bytes memory decodedVariableData) = this.decode2(extraData, expectedHash);
        assertEq(decodedFixedData, fixedData);
        assertEq(decodedVariableData, variableData);
    }

    function testDecode3() public {
        bytes memory variableData1 = "hello";
        bytes memory variableData2 = "world";
        bytes[] memory variableDataArrays = new bytes[](2);
        variableDataArrays[0] = variableData1;
        variableDataArrays[1] = variableData2;
        bytes memory extraData = abi.encodePacked(uint8(3), abi.encode(variableDataArrays));
        bytes[] memory decoded = this.decode3(extraData);
        assertEq(decoded.length, 2);
        assertEq(decoded[0], variableData1);
        assertEq(decoded[1], variableData2);
    }

    function testDecode4() public {
        bytes memory fixedData1 = "hello";
        bytes memory fixedData2 = "world";
        bytes[] memory fixedDataArrays = new bytes[](2);
        fixedDataArrays[0] = fixedData1;
        fixedDataArrays[1] = fixedData2;
        bytes32[] memory subhashes = new bytes32[](2);
        subhashes[0] = keccak256(fixedData1);
        subhashes[1] = keccak256(fixedData2);
        bytes32 expectedHash = keccak256(abi.encodePacked(subhashes));

        bytes memory extraData = abi.encodePacked(uint8(4), abi.encode(fixedDataArrays));
        bytes[] memory decoded = this.decode4(extraData, expectedHash);
        assertEq(decoded.length, 2);
        assertEq(decoded[0], fixedData1);
        assertEq(decoded[1], fixedData2);
    }

    function testDecode5() public {
        bytes memory fixedData1 = "hello";
        bytes memory fixedData2 = "world";
        bytes[] memory fixedDataArrays = new bytes[](2);
        fixedDataArrays[0] = fixedData1;
        fixedDataArrays[1] = fixedData2;
        bytes32[] memory subhashes = new bytes32[](2);
        subhashes[0] = keccak256(fixedData1);
        subhashes[1] = keccak256(fixedData2);
        bytes32 expectedHash = keccak256(abi.encodePacked(subhashes));

        bytes memory variableData1 = "hello2";
        bytes memory variableData2 = "world2";
        bytes[] memory variableDataArrays = new bytes[](2);
        variableDataArrays[0] = variableData1;
        variableDataArrays[1] = variableData2;

        bytes memory extraData = abi.encodePacked(uint8(5), abi.encode(fixedDataArrays, variableDataArrays));
        (bytes[] memory decodedFixed, bytes[] memory decodedVariable) = this.decode5(extraData, expectedHash);
        assertEq(decodedFixed.length, 2);
        assertEq(decodedFixed[0], fixedData1);
        assertEq(decodedFixed[1], fixedData2);
        assertEq(decodedVariable.length, 2);
        assertEq(decodedVariable[0], variableData1);
        assertEq(decodedVariable[1], variableData2);
    }

    function decode0(bytes calldata extraData) external pure returns (bytes memory) {
        return SIP6Decoder.decodeSubstandard0(extraData);
    }

    function decode1(bytes calldata extraData, bytes32 expectedHash) external pure returns (bytes memory) {
        return SIP6Decoder.decodeSubstandard1(extraData, expectedHash);
    }

    function decode2(bytes calldata extraData, bytes32 expectedHash) external returns (bytes memory, bytes memory) {
        return SIP6Decoder.decodeSubstandard2(extraData, expectedHash);
    }

    function decode3(bytes calldata extraData) external pure returns (bytes[] calldata) {
        return SIP6Decoder.decodeSubstandard3(extraData);
    }

    function decode4(bytes calldata extraData, bytes32 expectedHash) external returns (bytes[] memory) {
        return SIP6Decoder.decodeSubstandard4(extraData, expectedHash);
    }

    function decode5(bytes calldata extraData, bytes32 expectedHash)
        external
        pure
        returns (bytes[] memory, bytes[] memory)
    {
        (bytes[] memory a, bytes[] memory b) = abi.decode(extraData[1:], (bytes[], bytes[]));
        return SIP6Decoder.decodeSubstandard5(extraData, expectedHash);
    }
}
