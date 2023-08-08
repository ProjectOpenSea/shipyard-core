// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ERC721_OZ} from "shipyard-core/reference/tokens/erc721/ERC721Preapproved_OZ.sol";
import {CONDUIT} from "shipyard-core/lib/Constants.sol";
import {IERC0001} from "shipyard-core/interfaces/IERC0001.sol";

contract ERC721ConduitPreapproved_OZTest is Test, IERC0001 {
    ERC721_OZ test;

    function setUp() public {
        test = new ERC721_OZ();
    }

    function testConstructorEvent() public {
        vm.expectEmit(true, true, false, false);
        emit PreapprovalForAll(CONDUIT, true);
        new ERC721_OZ();
    }

    function testConstructor() public {
        assertTrue(test.isApprovedForAll(address(this), CONDUIT));
    }

    function testConduitPreapproved(address acct) public {
        assertTrue(test.isApprovedForAll(acct, CONDUIT));
        vm.prank(acct);
        test.setApprovalForAll(CONDUIT, false);
        assertFalse(test.isApprovedForAll(acct, CONDUIT));
    }

    function testConduitCanTransfer(address acct) public {
        if (acct == address(0)) {
            acct = address(1);
        }
        test.mint(address(acct), 1);
        vm.prank(CONDUIT);
        test.transferFrom(address(acct), address(this), 1);
    }
}
