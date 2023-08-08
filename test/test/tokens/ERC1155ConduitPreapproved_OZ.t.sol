// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ERC1155_OZ} from "shipyard-core/reference/tokens/erc1155/ERC1155Preapproved_OZ.sol";
import {CONDUIT} from "shipyard-core/lib/Constants.sol";

contract ERC1155ConduitPreapproved_OZTest is Test {
    ERC1155_OZ test;

    function setUp() public {
        test = new ERC1155_OZ();
    }

    function testConduitPreapproved(address acct) public {
        if (acct == address(0)) {
            acct = address(1);
        }
        assertTrue(test.isApprovedForAll(acct, CONDUIT));
        vm.prank(acct);
        test.setApprovalForAll(CONDUIT, false);
        assertFalse(test.isApprovedForAll(acct, CONDUIT));
    }

    function testNormalApprovals(address acct, address operator) public {
        if (acct == address(0)) {
            acct = address(1);
        }
        if (operator == address(0)) {
            operator = address(1);
        }
        vm.assume(operator != CONDUIT);
        vm.assume(acct != operator);
        assertFalse(test.isApprovedForAll(acct, operator));
        vm.prank(acct);
        test.setApprovalForAll(operator, true);
        assertTrue(test.isApprovedForAll(acct, operator));
        vm.prank(acct);
        test.setApprovalForAll(operator, false);
        assertFalse(test.isApprovedForAll(acct, operator));
    }

    function testConduitCanTransfer(address acct) public {
        vm.assume(acct.code.length == 0);
        if (acct == address(0)) {
            acct = address(1);
        }
        test.mint(address(acct), 1, 1);
        vm.prank(CONDUIT);
        test.safeTransferFrom(address(acct), address(this), 1, 1, "");
    }

    function testConduitCanBatchTransfer(address acct) public {
        vm.assume(acct.code.length == 0);

        if (acct == address(0)) {
            acct = address(1);
        }

        test.mint(address(acct), 1, 1);
        uint256[] memory ids = singletonArray(1);
        uint256[] memory amounts = singletonArray(1);
        vm.prank(CONDUIT);
        test.safeBatchTransferFrom(address(acct), address(this), ids, amounts, "");
    }

    function singletonArray(uint256 x) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](1);
        arr[0] = x;
        return arr;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
