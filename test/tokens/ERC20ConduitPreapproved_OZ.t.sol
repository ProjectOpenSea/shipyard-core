// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC20_OZ} from "src/reference/tokens/erc20/ERC20Preapproved_OZ.sol";
import {CONDUIT} from "src/lib/Constants.sol";
import {IPreapprovalForAll} from "src/interfaces/IPreapprovalForAll.sol";

contract ERC20ConduitPreapproved_OZTest is Test, IPreapprovalForAll {
    ERC20_OZ test;

    function setUp() public {
        test = new ERC20_OZ();
    }

    function testConstructorEvent() public {
        vm.expectEmit(true, true, false, false);
        emit PreapprovalForAll(CONDUIT, true);
        new ERC20_OZ();
    }

    function testConduitPreapproved(address acct) public {
        if (acct == address(0)) {
            acct = address(1);
        }
        assertEq(test.allowance(acct, CONDUIT), type(uint256).max);
        vm.prank(acct);
        test.approve(CONDUIT, 0);
        assertEq(test.allowance(acct, CONDUIT), 0);
        vm.prank(acct);
        test.approve(CONDUIT, 1 ether);
        assertEq(test.allowance(acct, CONDUIT), 1 ether);
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
        assertEq(test.allowance(acct, operator), 0);
        vm.prank(acct);
        test.approve(operator, 1 ether);
        assertEq(test.allowance(acct, operator), 1 ether);
        vm.prank(acct);
        test.approve(operator, 0);
        assertEq(test.allowance(acct, operator), 0);
    }

    function testConduitCanTransfer(address acct) public {
        if (acct == address(0)) {
            acct = address(1);
        }
        test.mint(address(acct), 1);
        vm.prank(CONDUIT);
        test.transferFrom(address(acct), address(this), 1);
    }

    function testTransferReducesAllowance(address acct, address operator) public {
        if (acct == address(0)) {
            acct = address(1);
        }
        if (operator == address(0)) {
            operator = address(1);
        }
        test.mint(acct, 1 ether);
        vm.prank(acct);
        test.approve(operator, 1 ether);
        vm.prank(operator);
        test.transferFrom(address(acct), address(this), 1 ether);
        assertEq(test.allowance(acct, operator), 0);
        assertEq(test.balanceOf(address(this)), 1 ether);

        // Allowance shouldn't decrease if type(uint256).max
        test.mint(acct, 1 ether);
        vm.prank(acct);
        test.approve(operator, type(uint256).max);
        vm.prank(operator);
        test.transferFrom(address(acct), address(this), 1 ether);
        assertEq(test.allowance(acct, operator), type(uint256).max);
        assertEq(test.balanceOf(address(this)), 2 ether);

        // Test conduit which should have default allowance of type(uint256).max
        test.mint(acct, 1 ether);
        assertEq(test.allowance(acct, CONDUIT), type(uint256).max);
        vm.prank(CONDUIT);
        test.transferFrom(address(acct), address(this), 1 ether);
        assertEq(test.allowance(acct, CONDUIT), type(uint256).max);
        assertEq(test.balanceOf(address(this)), 3 ether);

        // Test conduit with lower allowance that should be reduced
        test.mint(acct, 1 ether);
        vm.prank(acct);
        test.approve(CONDUIT, 1 ether);
        vm.prank(CONDUIT);
        test.transferFrom(address(acct), address(this), 1 ether);
        assertEq(test.allowance(acct, CONDUIT), 0);
        assertEq(test.balanceOf(address(this)), 4 ether);

        // Test conduit with now 0 allowance that should revert
        test.mint(acct, 1 ether);
        vm.prank(CONDUIT);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, CONDUIT, 0, 1 ether));
        test.transferFrom(address(acct), address(this), 1 ether);
    }
}
