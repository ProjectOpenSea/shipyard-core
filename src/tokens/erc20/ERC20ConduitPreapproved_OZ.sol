// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {CONDUIT} from "../../lib/Constants.sol";
import {IPreapprovalForAll} from "../../interfaces/IPreapprovalForAll.sol";

abstract contract ERC20ConduitPreapproved_OZ is ERC20, IPreapprovalForAll {
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
        uint256 allowance = super.allowance(owner, spender);
        if (spender == CONDUIT) {
            if (allowance == 0) {
                return type(uint256).max;
            } else if (allowance == type(uint256).max) {
                return 0;
            }
        }
        return allowance;
    }

    /**
     * @param owner Owner of tokens
     * @param spender Account to approve allowance of `owner`'s tokens
     * @param value Amount to approve
     * @param emitEvent Whether to emit the Approval event
     * @dev `allowance` inverts the value of the approval if `spender` is `CONDUIT`, since users must explicitly revoke the pre-approved conduit.
     *       E.g. if 0 is passed, it is stored as `type(uint256).max`, and if `type(uint256).max` is passed, it is stored as 0.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual override {
        if (spender == CONDUIT) {
            if (value == 0) {
                value = type(uint256).max;
            } else if (value == type(uint256).max) {
                value = 0;
            }
        }
        super._approve(owner, spender, value, emitEvent);
    }
}
