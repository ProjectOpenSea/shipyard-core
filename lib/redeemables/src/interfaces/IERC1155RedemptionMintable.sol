// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";

interface IERC1155RedemptionMintable {
    function mintRedemption(address to, SpentItem[] calldata spent) external returns (uint256 tokenId);
}
