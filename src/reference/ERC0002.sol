// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC0002} from "src/interfaces/IERC0002.sol";

/**
 * @title ERC0002 Queryable Reference Implementation
 */
contract ERC0002 is IERC0002 {
    function extsload(bytes32 slot) external view returns (bytes32) {
        assembly ("memory-safe") {
            mstore(0, sload(slot))
            return(0, 0x20)
        }
    }

    function extsload(bytes32 start, uint256 num) external view returns (bytes32[] memory) {
        assembly ("memory-safe") {
            // get free memory pointer; this is the pointer to the abi-encoded offset of the return array
            let ptr := mload(0x40)
            // store the abi-encoded offset of the return array
            mstore(ptr, 0x20)
            // assign values to the word after the offset
            let values := add(0x20, ptr)

            // store the length at 'values'
            mstore(values, num)
            // location in memory to start writing values (one word after length)
            let arrayStart := add(values, 0x20)

            // loop over slots and write sloads to memory
            for { let idx }
            // while idx < slots.bytes_length
            lt(idx, num) {
                // after each loop, increment idx by one word
                idx := add(1, idx)
            } {
                mstore(
                    // store value at start + idx * 0x20
                    add(arrayStart, shl(5, idx)),
                    // sload from slot
                    sload(add(idx, start))
                )
            }
            // return 1 word for the offset, 1 word for the length of the array, and the array itself
            return(ptr, add(0x40, shl(5, num)))
        }
    }

    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory) {
        assembly ("memory-safe") {
            // get free memory pointer; this is the pointer to the abi-encoded offset of the return array
            let ptr := mload(0x40)
            // store the abi-encoded offset of the return array
            mstore(ptr, 0x20)
            // assign values to the word after the offset
            let values := add(0x20, ptr)

            // store the length at 'values'
            mstore(values, slots.length)
            // location in memory to start writing values (one word after length)
            let arrayStart := add(values, 0x20)

            // calculate length of array in bytes
            let slotsBytesLength := shl(5, slots.length)

            // loop over slots and write sloads to memory
            for { let idx }
            // while idx < slots.bytes_length
            lt(idx, slotsBytesLength) {
                // after each loop, increment idx by one word
                idx := add(0x20, idx)
            } {
                mstore(
                    // store value at start + idx
                    add(arrayStart, idx),
                    // sload from slot
                    sload(
                        // load slot from calldata
                        calldataload(
                            // add idx bytes to slots.offset
                            add(idx, slots.offset)
                        )
                    )
                )
            }
            // return 1 word for the offset, 1 word for the length of the array, and the array itself
            return(ptr, add(0x40, slotsBytesLength))
        }
    }
}
