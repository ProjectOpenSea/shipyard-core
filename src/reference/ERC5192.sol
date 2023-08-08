// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "solady/tokens/ERC721.sol";
import {IERC5192} from "shipyard-core/interfaces/IERC5192.sol";

contract ERC5192 is ERC721, IERC5192 {
    error TokenLocked(uint256 tokenId);
    error TokenNotLocked(uint256 tokenId);

    function name() public pure override returns (string memory) {
        return "ERC5192Example";
    }

    function symbol() public pure override returns (string memory) {
        return "5192";
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked("https://example.com/token/", tokenId));
    }

    function stake(uint256 tokenId) public {
        // ensure staker is owner or approved
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner) {
            if (!isApprovedForAll(tokenOwner, msg.sender)) {
                revert NotOwnerNorApproved();
            }
        }

        // get the timestamp the token was locked at
        uint256 lockedAt = _getExtraData(tokenId);
        // if it is not empty, the token is already staked
        if (lockedAt != 0) {
            revert TokenLocked(tokenId);
        }
        // set the lockedAt timestamp to the current block timestamp
        _setExtraData(tokenId, uint96(block.timestamp));

        // emit the onchain event
        emit Locked(tokenId);
    }

    function unstake(uint256 tokenId) public {
        // ensure staker is owner or approved
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner) {
            if (!isApprovedForAll(tokenOwner, msg.sender)) {
                revert NotOwnerNorApproved();
            }
        }
        // get the timestamp the token was locked at
        uint256 lockedAt = _getExtraData(tokenId);
        // if it is empty, the token is not staked
        if (lockedAt == 0) {
            revert TokenNotLocked(tokenId);
        }
        // set the lockedAt timestamp to 0
        _setExtraData(tokenId, 0);
        // calculate the new "score" for the owner, which is total seconds staked across all tokens
        uint256 currentScore = _getAux(tokenOwner);
        // add the time since the token was locked to the current score
        uint256 newScore = currentScore + (block.timestamp - lockedAt);
        // set the new score
        _setAux(tokenOwner, uint224(newScore));
        // emit the onchain event
        emit Unlocked(tokenId);
    }

    function locked(uint256 tokenId) public view override returns (bool) {
        // ensure token exists
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        // return true if the token is locked
        return _getExtraData(tokenId) != 0;
    }

    function score(address owner) public view returns (uint256) {
        return _getAux(owner);
    }

    function _beforeTokenTransfer(address from, address, uint256 tokenId) internal view override {
        // if the token is being transferred from an address
        if (from != address(0)) {
            // ensure the token is not locked
            uint256 lockedAt = _getExtraData(tokenId);
            if (lockedAt != 0) {
                // else revert
                revert TokenLocked(tokenId);
            }
        }
    }
}
