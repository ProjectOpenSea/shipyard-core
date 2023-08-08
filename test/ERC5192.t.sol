// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ERC5192, IERC5192, ERC721} from "shipyard-core/reference/ERC5192.sol";

contract ERC5192Helper is ERC5192 {
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract ERC5192Test is Test {
    ERC5192Helper test;

    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    function setUp() public {
        test = new ERC5192Helper();
        test.mint(address(this), 1);
    }

    function testStake() public {
        assertFalse(test.locked(1));
        vm.expectEmit(true, false, false, true, address(test));
        emit Locked(1);
        test.stake(1);
        assertTrue(test.locked(1));
    }

    function testStake_Approved() public {
        test.setApprovalForAll(makeAddr("random"), true);
        vm.expectEmit(true, false, false, true, address(test));
        emit Locked(1);
        vm.prank(makeAddr("random"));
        test.stake(1);
        assertTrue(test.locked(1));
    }

    function testStake_TokenLocked() public {
        test.stake(1);
        assertTrue(test.locked(1));
        vm.expectRevert(abi.encodeWithSelector(ERC5192.TokenLocked.selector, 1));
        test.stake(1);
    }

    function testStake_NotOwnerOrApproved() public {
        vm.prank(makeAddr("random"));
        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
        test.stake(1);
    }

    function testUnstake() public {
        test.stake(1);
        assertTrue(test.locked(1));
        vm.expectEmit(true, false, false, true, address(test));
        emit Unlocked(1);
        test.unstake(1);
        assertFalse(test.locked(1));
    }

    function testUnstake_Approved() public {
        test.stake(1);
        assertTrue(test.locked(1));
        test.setApprovalForAll(makeAddr("random"), true);
        vm.expectEmit(true, false, false, true, address(test));
        emit Unlocked(1);
        vm.prank(makeAddr("random"));
        test.unstake(1);
        assertFalse(test.locked(1));
    }

    function testUnstake_TokenNotLocked() public {
        vm.expectRevert(abi.encodeWithSelector(ERC5192.TokenNotLocked.selector, 1));
        test.unstake(1);
    }

    function testUnstake_NotOwnerOrApproved() public {
        test.stake(1);
        assertTrue(test.locked(1));
        vm.prank(makeAddr("random"));
        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
        test.unstake(1);
    }

    function testLocked_NotExists() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        test.locked(2);
    }

    function testShim() public view {
        test.name();
        test.symbol();
        test.tokenURI(1);
    }

    function testScore() public {
        test.stake(1);
        vm.warp(block.timestamp + 100);
        test.unstake(1);
        uint256 score = test.score(address(this));
        assertEq(score, 100);
        test.stake(1);
        vm.warp(block.timestamp + 50);
        test.unstake(1);
        score = test.score(address(this));
        assertEq(score, 150);
    }

    function testTransfer() public {
        test.stake(1);
        assertTrue(test.locked(1));
        vm.expectRevert(abi.encodeWithSelector(ERC5192.TokenLocked.selector, 1));
        test.transferFrom(address(this), makeAddr("random"), 1);

        test.mint(address(this), 2);
        test.transferFrom(address(this), makeAddr("random"), 2);
    }
}
