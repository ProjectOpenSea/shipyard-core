// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import {CONDUIT} from "../../lib/Constants.sol";
import {IPreapprovalForAll} from "../../interfaces/IPreapprovalForAll.sol";

abstract contract ERC1155ConduitPreapproved_OZ is ERC1155, IPreapprovalForAll {
    constructor() {
        emit PreapprovalForAll(CONDUIT, true);
    }

    /**
     *
     * @param owner Owner of tokens
     * @param operator Account to check if approved to manage all of `owner`'s tokens
     * @dev If `operator` is `CONDUIT`, invert the value of the approval, since users must explicitly revoke the pre-approved conduit.
     *      E.g., if CONDUIT's approval slot is 0 (false), then `owner` has not revoked the pre-approval, so return the boolean opposite (true).
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        bool approved = super.isApprovedForAll(owner, operator);
        return (operator == CONDUIT) ? !approved : approved;
    }

    /**
     * Set whether `operator` is approved to manage all of `owner`'s tokens.
     * @param operator Owner of tokens
     * @param operator Operator account to update
     * @param approved Whether to approve or revoke approval
     * @dev If `operator` is `CONDUIT`, invert the value of the approval, since users must explicitly revoke the pre-approved conduit.
     *      E.g., if a user wants to update CONDUIT's approval to `false`, the contract should store a non-zero value in the approval slot.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual override {
        approved = (operator == CONDUIT) ? !approved : approved;
        super._setApprovalForAll(owner, operator, approved);
    }
}
