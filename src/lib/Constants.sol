// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @dev The canonical OpenSea conduit.
address constant CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;
/// @dev `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
uint256 constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE = 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;
/// @dev Pre-shifted and pre-masked constant.
uint256 constant SOLADY_ERC721_MASTER_SLOT_SEED_MASKED = 0x0a5a2e7a00000000;
/// @dev Solady ERC1155 master slot seed.
uint256 constant SOLADY_ERC1155_MASTER_SLOT_SEED = 0x9a31110384e0b0c9;
/// @dev `keccak256(bytes("TransferSingle(address,address,address,uint256,uint256)"))`.
uint256 constant SOLADY_TRANSFER_SINGLE_EVENT_SIGNATURE =
    0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62;
/// @dev `keccak256(bytes("TransferBatch(address,address,address,uint256[],uint256[])"))`.
uint256 constant SOLADY_TRANSFER_BATCH_EVENT_SIGNATURE =
    0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb;
/// @dev Solady ERC20 allowance slot seed.
uint256 constant SOLADY_ERC20_ALLOWANCE_SLOT_SEED = 0x7f5e9f20;
/// @dev Solady ERC20 balance slot seed.
uint256 constant SOLADY_ERC20_BALANCE_SLOT_SEED = 0x87a211a2;
/// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
uint256 constant SOLADY_ERC20_TRANSFER_EVENT_SIGNATURE =
    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
uint256 constant SOLADY_ERC20_APPROVAL_EVENT_SIGNATURE = 0;
/// @dev Solady ERC20 nonces slot seed with signature prefix.
uint256 constant SOLADY_ERC20_NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX = 0x383775081901;
/// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
bytes32 constant SOLADY_ERC20_DOMAIN_TYPEHASH =
0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
/// @dev Solady ERC20 version hash: `keccak256("1")`.
bytes32 constant SOLADY_ERC20_VERSION_HASH =
0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
/// @dev `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
bytes32 constant SOLADY_ERC20_PERMIT_TYPEHASH =
0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;