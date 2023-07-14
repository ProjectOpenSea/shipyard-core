// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC0001 {
    /// @notice Emitted when a token contract preapproves (or revokes) all token transfers from a specific address, if
    ///         the preapproval is configurable. This allows offchain indexers to correctly reflect token approvals
    ///         which can later be revoked.
    event PreapprovalForAll(address indexed operator, bool indexed approved);
}
