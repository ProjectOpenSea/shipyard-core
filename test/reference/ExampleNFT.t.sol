// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ExampleNFT} from "src/reference/ExampleNFT.sol";

contract ExampleNFTTest is Test {
    ExampleNFT test;

    function setUp() public {
        test = new ExampleNFT();
    }
}
