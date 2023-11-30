// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {TestPlus} from "solady/test/utils/TestPlus.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {ERC20_Solady} from "src/reference/tokens/erc20/ERC20Preapproved_Solady.sol";
import {CONDUIT, SOLADY_ERC20_PERMIT_TYPEHASH} from "src/lib/Constants.sol";
import {IPreapprovalForAll} from "src/interfaces/IPreapprovalForAll.sol";

contract ERC20ConduitPreapproved_SoladyTest is Test, TestPlus, IPreapprovalForAll {
    ERC20_Solady test;

    struct _TestTemps {
        address owner;
        address to;
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 privateKey;
        uint256 nonce;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        (t.owner, t.privateKey) = _randomSigner();
        t.to = _randomNonZeroAddress();
        t.amount = _random();
        t.deadline = _random();
    }

    function setUp() public {
        test = new ERC20_Solady();
    }

    function testConstructorEvent() public {
        vm.expectEmit(true, true, false, false);
        emit PreapprovalForAll(CONDUIT, true);
        new ERC20_Solady();
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
        vm.prank(acct);
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
        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        test.transferFrom(address(acct), address(this), 1 ether);
    }

    function testPermit() public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        _signPermit(t);
        _permit(t);
        _checkAllowanceAndNonce(t);
    }

    function testPermitToConduit() public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;
        t.to = CONDUIT;

        _signPermit(t);
        _permit(t);
        _checkAllowanceAndNonce(t);

        // Test amount 0
        t.amount = 0;
        t.nonce++;
        _signPermit(t);
        _permit(t);
        _checkAllowanceAndNonce(t);

        // Test amount type(uint256).max
        t.amount = type(uint256).max;
        t.nonce++;
        _signPermit(t);
        _permit(t);
        _checkAllowanceAndNonce(t);
    }

    function _signPermit(_TestTemps memory t) internal view {
        bytes32 innerHash =
            keccak256(abi.encode(SOLADY_ERC20_PERMIT_TYPEHASH, t.owner, t.to, t.amount, t.nonce, t.deadline));
        bytes32 domainSeparator = test.DOMAIN_SEPARATOR();
        bytes32 outerHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, innerHash));
        (t.v, t.r, t.s) = vm.sign(t.privateKey, outerHash);
    }

    function _permit(_TestTemps memory t) internal {
        address test_ = address(test);
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(sub(t, 0x20))
            mstore(sub(t, 0x20), 0xd505accf)
            pop(call(gas(), test_, 0, sub(t, 0x04), 0xe4, 0x00, 0x00))
            mstore(sub(t, 0x20), m)
        }
    }

    function _checkAllowanceAndNonce(_TestTemps memory t) internal {
        assertEq(test.allowance(t.owner, t.to), t.amount);
        assertEq(test.nonces(t.owner), t.nonce + 1);
    }
}
