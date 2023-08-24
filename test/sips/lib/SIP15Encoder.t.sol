// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SIP15Encoder, Comparator} from "src/sips/lib/SIP15Encoder.sol";

contract SIP15EncoderTest is Test {
    function testEncodeSubstandard1(uint8 comparator, address token, bytes32 traitKey, bytes32 expectedValue) public {
        comparator = uint8(bound(comparator, 0, 4));
        Comparator _comparator = Comparator(comparator);
        bytes memory encoded =
            SIP15Encoder.encodeSIP15Substandard1_Efficient(_comparator, token, traitKey, expectedValue);
        assertEq(encoded.length, 86, "incorrect length");
        this.assertPackedVersionByte(encoded, bytes1(0x00));
        this.assertPackedComparator(encoded, _comparator);
        this.assertPackedToken(encoded, token);
        this.assertPackedTraitKey(encoded, traitKey);
        this.assertPackedExpectedTraitValue(encoded, expectedValue);
    }

    function assertPackedVersionByte(bytes calldata data, bytes1 expectedVersion) external {
        assertEq(data[0], (expectedVersion), "incorrect version byte");
    }

    function assertPackedComparator(bytes calldata data, Comparator expectedComparator) external {
        assertEq(data[1], (bytes1(uint8(expectedComparator))), "incorrect comparator");
    }

    function assertPackedToken(bytes calldata data, address expectedToken) external {
        assertEq(data[2:22], abi.encodePacked(expectedToken), "incorrect token");
    }

    function assertPackedTraitKey(bytes calldata data, bytes32 expectedTraitKey) external {
        assertEq(data[22:54], abi.encodePacked(expectedTraitKey), "incorrect traitKey");
    }

    function assertPackedExpectedTraitValue(bytes calldata data, bytes32 expectedExpectedTraitValue) external {
        assertEq(data[54:86], abi.encodePacked(expectedExpectedTraitValue), "incorrect expectedTraitValue");
    }
}
