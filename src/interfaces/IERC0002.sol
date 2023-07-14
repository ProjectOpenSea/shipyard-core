// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ERC0000 Queryable Interface
 * @notice This ERC proposes a standard interface for querying arbitrary storage slots in a contract.
 */
interface IERC0002 {
    function extsload(bytes32 slot) external view returns (bytes32 value);

    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory values);
}
