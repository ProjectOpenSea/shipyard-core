// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC0002} from "src/interfaces/IERC0002.sol";

/**
 * @title ERC0000 Queryable Reference Implementation
 */

contract ERC0002 is IERC0002 {
    function load(uint256 slot) external view returns (bytes32 value) {
        assembly {
            value := sload(slot)
        }
    }
}
