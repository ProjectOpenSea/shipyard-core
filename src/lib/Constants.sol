// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @dev The canonical OpenSea conduit.
address constant CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;
/// @dev `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
uint256 constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE = 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;
/// @dev Pre-shifted and pre-masked constant.
uint256 constant SOLADY_ERC721_MASTER_SLOT_SEED_MASKED = 0x0a5a2e7a00000000;
