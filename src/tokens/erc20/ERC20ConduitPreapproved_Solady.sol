// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {
    CONDUIT,
    SOLADY_ERC20_ALLOWANCE_SLOT_SEED,
    SOLADY_ERC20_BALANCE_SLOT_SEED,
    SOLADY_ERC20_TRANSFER_EVENT_SIGNATURE
} from "../../lib/Constants.sol";
import {IPreapprovalForAll} from "../../interfaces/IPreapprovalForAll.sol";

abstract contract ERC20ConduitPreapproved_Solady is ERC20, IPreapprovalForAll {
    constructor() {
        emit PreapprovalForAll(CONDUIT, true);
    }

    /**
     * @param owner Owner of tokens
     * @param spender Account to check allowance of `owner`'s tokens
     * @dev If `spender` is `CONDUIT` and allowance is 0, return `type(uint256).max`, since users must explicitly revoke the pre-approved conduit.
     *      Setting an allowance of 0 for the conduit with `approve` will revoke the pre-approval.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        uint256 allowance_ = super.allowance(owner, spender);
        if (spender == CONDUIT) {
            if (allowance_ == 0) {
                return type(uint256).max;
            } else if (allowance_ == type(uint256).max) {
                return 0;
            }
        }
        return allowance_;
    }

    /**
     * @param spender Account to approve allowance of `msg.sender`'s tokens
     * @param amount Amount to approve
     * @dev `allowance` inverts the value of the approval if `spender` is `CONDUIT`, since users must explicitly revoke the pre-approved conduit.
     *       E.g. if 0 is passed, it is stored as `type(uint256).max`, and if `type(uint256).max` is passed, it is stored as 0.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        if (spender == CONDUIT) {
            if (amount == 0) {
                amount = type(uint256).max;
            } else if (amount == type(uint256).max) {
                amount = 0;
            }
        }
        super._approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, SOLADY_ERC20_ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)

            // "flip" allowance if caller is CONDUIT and if allowance_ is 0 or type(uint256).max.
            allowance_ :=
                xor(allowance_, mul(and(eq(caller(), CONDUIT), iszero(and(allowance_, not(allowance_)))), not(0)))

            // If the allowance is not the maximum uint256 value:
            if not(allowance_) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }

            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, SOLADY_ERC20_BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, SOLADY_ERC20_TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual override {
        if (spender == CONDUIT) {
            uint256 allowance_ = super.allowance(owner, spender);
            if (allowance_ == type(uint256).max) {
                // Max allowance, no need to spend.
                return;
            } else if (allowance_ == 0) {
                revert InsufficientAllowance();
            }
        }
        super._spendAllowance(owner, spender, amount);
    }
}
