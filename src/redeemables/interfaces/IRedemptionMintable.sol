// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ConsiderationItem} from "seaport-types/lib/ConsiderationStructs.sol";

interface IRedemptionMintable {
    function mintRedemption(uint256 campaignId, address recipient, ConsiderationItem[] memory consideration) external;
}
