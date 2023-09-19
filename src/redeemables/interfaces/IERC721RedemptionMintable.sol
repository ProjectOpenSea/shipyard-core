// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SpentItem} from "seaport-types/lib/ConsiderationStructs.sol";

interface IERC721RedemptionMintable {
    function mintRedemption(address to, uint256 tokenId) external returns (uint256);
}

// import {ConsiderationItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";

// interface IERC721RedemptionMintable {
//     function mintRedemption(
//         uint256 campaignId,
//         address recipient,
//         ConsiderationItem[] memory consideration
//     ) external returns (uint256[] memory tokenIds);
// }
