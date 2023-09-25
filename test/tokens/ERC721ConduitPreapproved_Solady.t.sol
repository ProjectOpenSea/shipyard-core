// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ERC721_Solady} from "src/reference/tokens/erc721/ERC721Preapproved_Solady.sol";
import {CONDUIT} from "src/lib/Constants.sol";
import {IPreapprovalForAll} from "src/interfaces/IPreapprovalForAll.sol";

contract ERC721ConduitPreapproved_SoladyTest is Test, IPreapprovalForAll {
    ERC721_Solady test;

    function setUp() public {
        test = new ERC721_Solady();
    }

    function testConstructorEvent() public {
        vm.expectEmit(true, true, false, false);
        emit PreapprovalForAll(CONDUIT, true);
        new ERC721_Solady();
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
