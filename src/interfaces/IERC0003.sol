// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ERC0003 Contract-Level URI
 * @notice This ERC proposes a standard interface for querying arbitrary storage slots in a contract.
 */
interface IERC0003 {
    event ContractURIUpdated();

    function contractURI() external view returns (string memory);
}
