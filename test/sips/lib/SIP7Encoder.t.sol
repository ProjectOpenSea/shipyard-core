// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SIP7Encoder} from "src/sips/lib/SIP7Encoder.sol";
import {ItemType} from "seaport-types/lib/ConsiderationEnums.sol";
import {ReceivedItem} from "seaport-types/lib/ConsiderationStructs.sol";

contract SIP7EncoderTest is Test {
    function testEncodeSubstandard1() public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard1(1);
        assertEq(encoded.length, 33);
        assertEq(encoded[0], bytes1(0x01));
        bytes memory sliced = this.slice(encoded, 1);
        uint256 result = abi.decode(sliced, (uint256));
        assertEq(result, 1);
    }

    function testEncodeSubstandard2() public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard2(ItemType(1), address(2), 3, 4, address(5));
        assertEq(encoded.length, 161);
        assertEq(encoded[0], bytes1(0x02));
        bytes memory sliced = this.slice(encoded, 1);
        (ItemType itemType, address token, uint256 identifier, uint256 amount, address recipient) =
            abi.decode(sliced, (ItemType, address, uint256, uint256, address));
        assertEq(uint256(itemType), 1, "incorrect itemType");
        assertEq(token, address(2), "incorrect token");
        assertEq(identifier, 3, "incorrect identifier");
        assertEq(amount, 4, "incorrect amount");
        assertEq(recipient, address(5), "incorrect recipient");

        ReceivedItem memory item = ReceivedItem(itemType, token, identifier, amount, payable(recipient));
        encoded = SIP7Encoder.encodeSubstandard2(item);
        assertEq(encoded.length, 161);
        assertEq(encoded[0], bytes1(0x02));
        sliced = this.slice(encoded, 1);
        (itemType, token, identifier, amount, recipient) =
            abi.decode(sliced, (ItemType, address, uint256, uint256, address));
        assertEq(uint256(itemType), 1, "incorrect itemType");
        assertEq(token, address(2), "incorrect token");
        assertEq(identifier, 3, "incorrect identifier");
        assertEq(amount, 4, "incorrect amount");
        assertEq(recipient, address(5), "incorrect recipient");
    }

    function testEncodeSubstandard3() public {
        bytes memory encoded = SIP7Encoder.encodeSubstandard3(bytes32(uint256(1234)));
        assertEq(encoded.length, 33);
        assertEq(encoded[0], bytes1(0x03));
        bytes memory sliced = this.slice(encoded, 1);
        bytes32 result = abi.decode(sliced, (bytes32));
        assertEq(result, bytes32(uint256(1234)));
    }

    function testEncodeSubstandard4() public {
        bytes32[] memory hashes = new bytes32[](2);
        hashes[0] = bytes32(uint256(1234));
        hashes[1] = bytes32(uint256(5678));
        bytes memory encoded = SIP7Encoder.encodeSubstandard4(hashes);
        assertEq(encoded.length, 129);
        assertEq(encoded[0], bytes1(0x04));
        bytes memory sliced = this.slice(encoded, 1);
        bytes32[] memory result = abi.decode(sliced, (bytes32[]));
        assertEq(result.length, 2);
        assertEq(result[0], bytes32(uint256(1234)));
        assertEq(result[1], bytes32(uint256(5678)));
    }

    function slice(bytes calldata data, uint256 start) external pure returns (bytes memory) {
        return data[start:];
    }
}
