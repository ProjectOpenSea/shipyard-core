// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IERC721Receiver} from "seaport-types/src/interfaces/IERC721Receiver.sol";

contract ERC721Recipient is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
