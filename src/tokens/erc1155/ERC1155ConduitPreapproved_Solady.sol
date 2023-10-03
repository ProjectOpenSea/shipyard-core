// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "solady/src/tokens/ERC1155.sol";
import {
    CONDUIT,
    _APPROVAL_FOR_ALL_EVENT_SIGNATURE,
    SOLADY_ERC1155_MASTER_SLOT_SEED,
    SOLADY_TRANSFER_SINGLE_EVENT_SIGNATURE,
    SOLADY_TRANSFER_BATCH_EVENT_SIGNATURE
} from "../../lib/Constants.sol";
import {IPreapprovalForAll} from "../../interfaces/IPreapprovalForAll.sol";

abstract contract ERC1155ConduitPreapproved_Solady is ERC1155, IPreapprovalForAll {
    constructor() {
        emit PreapprovalForAll(CONDUIT, true);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        bool approved = super.isApprovedForAll(owner, operator);
        return (operator == CONDUIT) ? !approved : approved;
    }

    function setApprovalForAll(address operator, bool isApproved) public virtual override {
        /// @solidity memory-safe-assembly
        assembly {
            // Convert to 0 or 1.
            isApproved := iszero(iszero(isApproved))
            let isConduit := eq(operator, CONDUIT)
            // if isConduit, flip isApproved, otherwise leave as is
            let storedValue :=
                or(
                    // isConduit && !isApproved
                    and(isConduit, iszero(isApproved)),
                    // !isConduit && isApproved
                    and(iszero(isConduit), isApproved)
                )
            // Update the `isApproved` for (`msg.sender`, `operator`).
            mstore(0x20, SOLADY_ERC1155_MASTER_SLOT_SEED)
            mstore(0x14, caller())
            mstore(0x00, operator)
            sstore(keccak256(0x0c, 0x34), storedValue)
            // Emit the {ApprovalForAll} event.
            mstore(0x00, isApproved)
            // forgefmt: disable-next-line
            log3(0x00, 0x20, _APPROVAL_FOR_ALL_EVENT_SIGNATURE, caller(), shr(96, shl(96, operator)))
        }
    }

    /// @dev Transfers `amount` of `id` from `from` to `to`.
    ///
    /// Requirements:
    /// - `to` cannot be the zero address.
    /// - `from` must have at least `amount` of `id`.
    /// - If the caller is not `from`,
    ///   it must be approved to manage the tokens of `from`.
    /// - If `to` refers to a smart contract, it must implement
    ///   {ERC1155-onERC1155Reveived}, which is called upon a batch transfer.
    ///
    /// Emits a {Transfer} event.
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data)
        public
        virtual
        override
    {
        if (_useBeforeTokenTransfer()) {
            _beforeTokenTransfer(from, to, _singleton(id), _singleton(amount), data);
        }
        /// @solidity memory-safe-assembly
        assembly {
            let fromSlotSeed := or(SOLADY_ERC1155_MASTER_SLOT_SEED, shl(96, from))
            let toSlotSeed := or(SOLADY_ERC1155_MASTER_SLOT_SEED, shl(96, to))
            mstore(0x20, fromSlotSeed)
            // Clear the upper 96 bits.
            from := shr(96, fromSlotSeed)
            to := shr(96, toSlotSeed)
            // Revert if `to` is the zero address.
            if iszero(to) {
                mstore(0x00, 0xea553b34) // `TransferToZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // If the caller is not `from`, do the authorization check.
            if iszero(eq(caller(), from)) {
                let isConduit := eq(caller(), CONDUIT)
                mstore(0x00, caller())
                let isApproved := sload(keccak256(0x0c, 0x34))
                // if isConduit, flip isApproved, otherwise leave as is
                isApproved :=
                    or(
                        // isConduit && !isApproved
                        and(isConduit, iszero(isApproved)),
                        // !isConduit && isApproved
                        and(iszero(isConduit), isApproved)
                    )
                if iszero(isApproved) {
                    mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                    revert(0x1c, 0x04)
                }
            }
            // Subtract and store the updated balance of `from`.
            {
                mstore(0x00, id)
                let fromBalanceSlot := keccak256(0x00, 0x40)
                let fromBalance := sload(fromBalanceSlot)
                if gt(amount, fromBalance) {
                    mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                    revert(0x1c, 0x04)
                }
                sstore(fromBalanceSlot, sub(fromBalance, amount))
            }
            // Increase and store the updated balance of `to`.
            {
                mstore(0x20, toSlotSeed)
                let toBalanceSlot := keccak256(0x00, 0x40)
                let toBalanceBefore := sload(toBalanceSlot)
                let toBalanceAfter := add(toBalanceBefore, amount)
                if lt(toBalanceAfter, toBalanceBefore) {
                    mstore(0x00, 0x01336cea) // `AccountBalanceOverflow()`.
                    revert(0x1c, 0x04)
                }
                sstore(toBalanceSlot, toBalanceAfter)
            }
            // Emit a {TransferSingle} event.
            mstore(0x20, amount)
            log4(0x00, 0x40, SOLADY_TRANSFER_SINGLE_EVENT_SIGNATURE, caller(), from, to)
        }
        if (_useAfterTokenTransfer()) {
            _afterTokenTransfer(from, to, _singleton(id), _singleton(amount), data);
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Do the {onERC1155Received} check if `to` is a smart contract.
            if extcodesize(to) {
                // Prepare the calldata.
                let m := mload(0x40)
                // `onERC1155Received(address,address,uint256,uint256,bytes)`.
                mstore(m, 0xf23a6e61)
                mstore(add(m, 0x20), caller())
                mstore(add(m, 0x40), from)
                mstore(add(m, 0x60), id)
                mstore(add(m, 0x80), amount)
                mstore(add(m, 0xa0), 0xa0)
                calldatacopy(add(m, 0xc0), sub(data.offset, 0x20), add(0x20, data.length))
                // Revert if the call reverts.
                if iszero(call(gas(), to, 0, add(m, 0x1c), add(0xc4, data.length), m, 0x20)) {
                    if returndatasize() {
                        // Bubble up the revert if the call reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    mstore(m, 0)
                }
                // Load the returndata and compare it with the function selector.
                if iszero(eq(mload(m), shl(224, 0xf23a6e61))) {
                    mstore(0x00, 0x9c05499b) // `TransferToNonERC1155ReceiverImplementer()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Transfers `amounts` of `ids` from `from` to `to`.
    ///
    /// Requirements:
    /// - `to` cannot be the zero address.
    /// - `from` must have at least `amount` of `id`.
    /// - `ids` and `amounts` must have the same length.
    /// - If the caller is not `from`,
    ///   it must be approved to manage the tokens of `from`.
    /// - If `to` refers to a smart contract, it must implement
    ///   {ERC1155-onERC1155BatchReveived}, which is called upon a batch transfer.
    ///
    /// Emits a {TransferBatch} event.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        if (_useBeforeTokenTransfer()) {
            _beforeTokenTransfer(from, to, ids, amounts, data);
        }
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(ids.length, amounts.length)) {
                mstore(0x00, 0x3b800a46) // `ArrayLengthsMismatch()`.
                revert(0x1c, 0x04)
            }
            let fromSlotSeed := or(SOLADY_ERC1155_MASTER_SLOT_SEED, shl(96, from))
            let toSlotSeed := or(SOLADY_ERC1155_MASTER_SLOT_SEED, shl(96, to))
            mstore(0x20, fromSlotSeed)
            // Clear the upper 96 bits.
            from := shr(96, fromSlotSeed)
            to := shr(96, toSlotSeed)
            // Revert if `to` is the zero address.
            if iszero(to) {
                mstore(0x00, 0xea553b34) // `TransferToZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // If the caller is not `from`, do the authorization check.
            if iszero(eq(caller(), from)) {
                let isConduit := eq(caller(), CONDUIT)
                mstore(0x00, caller())
                let isApproved := sload(keccak256(0x0c, 0x34))
                // if isConduit, flip isApproved, otherwise leave as is
                isApproved :=
                    or(
                        // isConduit && !isApproved
                        and(isConduit, iszero(isApproved)),
                        // !isConduit && isApproved
                        and(iszero(isConduit), isApproved)
                    )
                if iszero(isApproved) {
                    mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                    revert(0x1c, 0x04)
                }
            }
            // Loop through all the `ids` and update the balances.
            {
                let end := shl(5, ids.length)
                for { let i := 0 } iszero(eq(i, end)) { i := add(i, 0x20) } {
                    let amount := calldataload(add(amounts.offset, i))
                    // Subtract and store the updated balance of `from`.
                    {
                        mstore(0x20, fromSlotSeed)
                        mstore(0x00, calldataload(add(ids.offset, i)))
                        let fromBalanceSlot := keccak256(0x00, 0x40)
                        let fromBalance := sload(fromBalanceSlot)
                        if gt(amount, fromBalance) {
                            mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                            revert(0x1c, 0x04)
                        }
                        sstore(fromBalanceSlot, sub(fromBalance, amount))
                    }
                    // Increase and store the updated balance of `to`.
                    {
                        mstore(0x20, toSlotSeed)
                        let toBalanceSlot := keccak256(0x00, 0x40)
                        let toBalanceBefore := sload(toBalanceSlot)
                        let toBalanceAfter := add(toBalanceBefore, amount)
                        if lt(toBalanceAfter, toBalanceBefore) {
                            mstore(0x00, 0x01336cea) // `AccountBalanceOverflow()`.
                            revert(0x1c, 0x04)
                        }
                        sstore(toBalanceSlot, toBalanceAfter)
                    }
                }
            }
            // Emit a {TransferBatch} event.
            {
                let m := mload(0x40)
                // Copy the `ids`.
                mstore(m, 0x40)
                let n := add(0x20, shl(5, ids.length))
                let o := add(m, 0x40)
                calldatacopy(o, sub(ids.offset, 0x20), n)
                // Copy the `amounts`.
                mstore(add(m, 0x20), add(0x40, n))
                o := add(o, n)
                n := add(0x20, shl(5, amounts.length))
                calldatacopy(o, sub(amounts.offset, 0x20), n)
                n := sub(add(o, n), m)
                // Do the emit.
                log4(m, n, SOLADY_TRANSFER_BATCH_EVENT_SIGNATURE, caller(), from, to)
            }
        }
        if (_useAfterTokenTransfer()) {
            _afterTokenTransferCalldata_(from, to, ids, amounts, data);
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Do the {onERC1155BatchReceived} check if `to` is a smart contract.
            if extcodesize(to) {
                let m := mload(0x40)
                // Prepare the calldata.
                // `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)`.
                mstore(m, 0xbc197c81)
                mstore(add(m, 0x20), caller())
                mstore(add(m, 0x40), from)
                // Copy the `ids`.
                mstore(add(m, 0x60), 0xa0)
                let n := add(0x20, shl(5, ids.length))
                let o := add(m, 0xc0)
                calldatacopy(o, sub(ids.offset, 0x20), n)
                // Copy the `amounts`.
                let s := add(0xa0, n)
                mstore(add(m, 0x80), s)
                o := add(o, n)
                n := add(0x20, shl(5, amounts.length))
                calldatacopy(o, sub(amounts.offset, 0x20), n)
                // Copy the `data`.
                mstore(add(m, 0xa0), add(s, n))
                o := add(o, n)
                n := add(0x20, data.length)
                calldatacopy(o, sub(data.offset, 0x20), n)
                n := sub(add(o, n), add(m, 0x1c))
                // Revert if the call reverts.
                if iszero(call(gas(), to, 0, add(m, 0x1c), n, m, 0x20)) {
                    if returndatasize() {
                        // Bubble up the revert if the call reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    mstore(m, 0)
                }
                // Load the returndata and compare it with the function selector.
                if iszero(eq(mload(m), shl(224, 0xbc197c81))) {
                    mstore(0x00, 0x9c05499b) // `TransferToNonERC1155ReceiverImplementer()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Helper for calling the `_afterTokenTransfer` hook.
    /// The is to help the compiler avoid producing dead bytecode.
    function _afterTokenTransferCalldata_(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) private {
        if (_useAfterTokenTransfer()) {
            _afterTokenTransfer(from, to, ids, amounts, data);
        }
    }

    /// @dev Returns `x` in an array with a single element.
    function _singleton(uint256 x) private pure returns (uint256[] memory result) {
        assembly {
            result := mload(0x40)
            mstore(0x40, add(result, 0x40))
            mstore(result, 1)
            mstore(add(result, 0x20), x)
        }
    }
}
