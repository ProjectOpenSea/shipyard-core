// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IERC1155Receiver} from "../../../src/interfaces/IERC1155Receiver.sol";

contract ERC1155Recipient is IERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        virtual
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}
