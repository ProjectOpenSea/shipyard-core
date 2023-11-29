// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ExampleNFT} from "src/reference/ExampleNFT.sol";

contract ExampleNFTTest is Test {
    ExampleNFT testExampleNft;

    function setUp() public {
        testExampleNft = new ExampleNFT("Example", "EXNFT");
    }

    function testName() public {
        assertEq(testExampleNft.name(), "ExampleNFT");
    }

    function testSymbol() public {
        assertEq(testExampleNft.symbol(), "EXNFT");
    }
}
