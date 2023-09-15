// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {SignatureCheckerLib} from "solady/src/utils/SignatureCheckerLib.sol";
import {SignedRedeemErrorsAndEvents} from "./SignedRedeemErrorsAndEvents.sol";

contract SignedRedeemContractOfferer is SignedRedeemErrorsAndEvents {
    /// @dev The used digests, each digest can only be used once.
    mapping(bytes32 => bool) internal _usedDigests;

    /// @notice Internal constants for EIP-712: Typed structured
    ///         data hashing and signing
    bytes32 internal constant _SIGNED_REDEEM_TYPEHASH =
        keccak256("SignedRedeem(address owner,address token,uint256[] tokenIds,bytes32 redemptionHash,uint256 salt)");
    bytes32 internal constant _EIP_712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 internal constant _NAME_HASH = keccak256("SignedRedeem");
    bytes32 internal constant _VERSION_HASH = keccak256("1.0");
    uint256 internal immutable _CHAIN_ID = block.chainid;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    constructor() {
        _DOMAIN_SEPARATOR = _deriveDomainSeparator();
    }

    function _verifySignature(
        address signer,
        address owner,
        SpentItem[] memory maximumSpent,
        bytes32 redemptionHash,
        uint256 salt,
        bytes memory signature,
        bool recordDigest
    ) internal {
        // Get the digest.
        bytes32 digest = _getDigest(owner, maximumSpent, redemptionHash, salt);

        // Revert if signature does not recover to signer.
        if (!SignatureCheckerLib.isValidSignatureNow(signer, digest, signature)) revert InvalidSigner();

        // Revert if the digest is already used.
        if (_usedDigests[digest]) revert DigestAlreadyUsed();

        // Record digest as used.
        if (recordDigest) _usedDigests[digest] = true;
    }

    /*
     * @notice Verify an EIP-712 signature by recreating the data structure
     *         that we signed on the client side, and then using that to recover
     *         the address that signed the signature for this data.
     */
    function _getDigest(address owner, SpentItem[] memory maximumSpent, bytes32 redemptionHash, uint256 salt)
        internal
        view
        returns (bytes32 digest)
    {
        digest = keccak256(
            bytes.concat(
                bytes2(0x1901),
                _domainSeparator(),
                keccak256(abi.encode(_SIGNED_REDEEM_TYPEHASH, owner, maximumSpent, redemptionHash, salt))
            )
        );
    }

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     *
     * @return The domain separator.
     */
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == _CHAIN_ID ? _DOMAIN_SEPARATOR : _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return The derived domain separator.
     */
    function _deriveDomainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(_EIP_712_DOMAIN_TYPEHASH, _NAME_HASH, _VERSION_HASH, block.chainid, address(this)));
    }
}
