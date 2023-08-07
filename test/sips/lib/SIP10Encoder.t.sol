// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SIP10Encoder} from "shipyard-core/sips/lib/SIP10Encoder.sol";

contract SIP10EncoderTest is Test {
    function testEncodeSubstandard1() public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard1();
        assertEq(encoded.length, 1, "incorrect length");
        assertEq(encoded[0], bytes1(0x01), "incorrect version byte");

        encoded = SIP10Encoder.encodeSubstandard1Efficient();
        assertEq(encoded.length, 1, "incorrect length");
        assertEq(encoded[0], bytes1(0x00), "incorrect version byte");
    }

    function testEncodeSubstandard2(uint256 tokenId) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard2(tokenId);
        assertUint(encoded, 0x02, tokenId);
    }

    function testEncodeSubstandard3(uint256[] memory tokenIds) public {
        // bytes32 seed = keccak256(abi.encode(tokenIds));
        // LibPRNG.PRNG memory prng = LibPRNG.PRNG(uint256(seed));
        // uint256 len = prng.uniform(10);
        // uint256[] memory truncatedIds = new uint256[](10);
        // for (uint256 i; i < len; i++) {
        //     truncatedIds[i] = tokenIds[i];
        // }
        bytes memory encoded = SIP10Encoder.encodeSubstandard3(tokenIds);

        assertUintArray(encoded, 0x03, tokenIds);

        // assertEq(encoded[0], bytes1(0x03), "incorrect version byte");
        // bytes memory sliced = this.slice(encoded, 1);
        // uint256[] memory result = abi.decode(sliced, (uint256[]));
        // assertEq(keccak256(abi.encode(truncatedIds)), keccak256(abi.encode(result)), "incorrect result");
    }

    function testEncodeSubstandard4() public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard4();
        assertEq(encoded.length, 1, "incorrect length");
        assertEq(encoded[0], bytes1(0x04), "incorrect version byte");
    }

    function testEncodeSubstandard5(uint256 num) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard5(num);
        assertUint(encoded, 0x05, num);
    }

    function testEncodeSubstandard6(bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard6(data);
        assertPackedBytes(encoded, 0x06, data);
    }

    function testEncodeSubstandard7(bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard7(data);
        assertPackedBytes(encoded, 0x07, data);
    }

    function testEncodeSubstandard8(uint256 num, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard8(num, data);
        assertUintPackedBytes(encoded, 0x08, num, data);
    }

    function testEncodeSubstandard9(uint256[] memory numbers, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard9(numbers, data);
        uint256 end = numbers.length * 32 + 0x41;
        bytes memory sliced = this.slice(encoded, 0, end);
        assertUintArray(sliced, 0x09, numbers);

        if (data.length == 0) {
            sliced = "";
        } else {
            sliced = this.slice(encoded, end);
        }
        assertEq(data, sliced, "incorrect data");
    }

    function testEncodeSubstandard10(bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard10(data);
        assertPackedBytes(encoded, bytes1(uint8(10)), data);
    }

    function testEncodeSubstandard11(uint256 num, bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard11(num, data);
        assertUintPackedBytes(encoded, bytes1(uint8(11)), num, data);
    }

    function testEncodeSubstandard12(bytes memory data) public {
        bytes memory encoded = SIP10Encoder.encodeSubstandard12(data);
        assertPackedBytes(encoded, 0x0c, data);
    }

    function assertUintArray(bytes memory encoded, bytes1 version, uint256[] memory nums) internal {
        assertEq(encoded[0], bytes1(version), "incorrect version byte");
        bytes memory sliced = this.slice(encoded, 1);
        uint256[] memory result = abi.decode(sliced, (uint256[]));
        assertEq(keccak256(abi.encode(nums)), keccak256(abi.encode(result)), "incorrect result");
    }

    function assertUint(bytes memory encoded, bytes1 version, uint256 num) internal {
        assertEq(encoded.length, 33, "incorrect length");
        assertEq(encoded[0], version, "incorrect version byte");
        bytes memory sliced = this.slice(encoded, 1, encoded.length);
        uint256 result = abi.decode(sliced, (uint256));
        assertEq(result, num, "incorrect tokenId");
    }

    function assertPackedBytes(bytes memory encoded, bytes1 version, bytes memory data) internal {
        assertEq(encoded.length, data.length + 1);
        assertEq(encoded[0], version);
        bytes memory sliced = this.slice(encoded, 1, encoded.length);
        assertEq(sliced, abi.encodePacked(data));
    }

    function assertUintPackedBytes(bytes memory encoded, bytes1 version, uint256 num, bytes memory data) internal {
        bytes memory sliced = this.slice(encoded, 0, 0x21);
        assertUint(sliced, version, num);
        if (data.length == 0) {
            sliced = "";
        } else {
            sliced = this.slice(encoded, 0x21);
        }
        assertEq(data, sliced, "incorrect data");
    }

    function slice(bytes calldata data, uint256 start) external pure returns (bytes memory) {
        return data[start:];
    }

    function slice(bytes calldata data, uint256 start, uint256 end) external pure returns (bytes memory) {
        return data[start:end];
    }
}
