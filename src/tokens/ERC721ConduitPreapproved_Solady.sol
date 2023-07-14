// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "solady/tokens/ERC721.sol";
import {CONDUIT, _APPROVAL_FOR_ALL_EVENT_SIGNATURE, SOLADY_ERC721_MASTER_SLOT_SEED_MASKED} from "../lib/Constants.sol";
import {IERC0001} from "../interfaces/IERC0001.sol";

abstract contract ERC721ConduitPreapproved_Solady is ERC721, IERC0001 {
    constructor() {
        emit PreapprovalForAll(CONDUIT, true);
    }

    function transferFrom(address from, address to, uint256 id) public payable virtual override {
        _transfer(_by(from), from, to, id);
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
            mstore(0x1c, operator)
            mstore(0x08, SOLADY_ERC721_MASTER_SLOT_SEED_MASKED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x30), storedValue)
            // Emit the {ApprovalForAll} event.
            mstore(0x00, isApproved)
            log3(0x00, 0x20, _APPROVAL_FOR_ALL_EVENT_SIGNATURE, caller(), shr(96, shl(96, operator)))
        }
    }

    function _by(address from) internal view returns (address result) {
        if (msg.sender == CONDUIT) {
            if (isApprovedForAll(from, CONDUIT)) {
                return address(0);
            }
        }
        return msg.sender;
    }
}
