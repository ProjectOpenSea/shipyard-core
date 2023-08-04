// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";

contract SIP10DecoderTest is Test {
    function getSubstandardVersion(bytes calldata extraData) internal pure returns (bytes1) {
        return extraData[0];
    }
}
