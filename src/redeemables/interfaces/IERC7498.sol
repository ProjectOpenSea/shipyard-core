// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OfferItem, ConsiderationItem, SpentItem} from "seaport-types/lib/ConsiderationStructs.sol";
import {CampaignParams, TraitRedemption} from "../lib/RedeemablesStructs.sol";

interface IERC7498 {
    /* Events */
    // event CampaignUpdated(
    //     uint256 indexed campaignId,
    //     CampaignParams params,
    //     string URI
    // );
    // event Redemption(
    //     uint256 indexed campaignId,
    //     bytes32 redemptionHash,
    //     uint256[] tokenIds,
    //     address redeemedBy
    // );

    /* Structs */
    // struct CampaignParams {
    //     uint32 startTime;
    //     uint32 endTime;
    //     uint32 maxCampaignRedemptions;
    //     address manager; // the address that can modify the campaign
    //     address signer; // null address means no EIP-712 signature required
    //     OfferItem[] offer; // items to be minted, can be empty for offchain redeemable
    //     ConsiderationItem[] consideration; // the items you are transferring to recipient
    // }

    // struct TraitRedemption {
    //     uint8 substandard;
    //     address token;
    //     uint256 identifier;
    //     bytes32 traitKey;
    //     bytes32 traitValue;
    //     bytes32 substandardValue;
    // }

    /* Getters */
    function getCampaign(uint256 campaignId)
        external
        view
        returns (CampaignParams memory params, string memory uri, uint256 totalRedemptions);

    /* Setters */
    function createCampaign(CampaignParams calldata params, string calldata uri)
        external
        returns (uint256 campaignId);

    function updateCampaign(uint256 campaignId, CampaignParams calldata params, string calldata uri) external;

    function redeem(uint256[] calldata tokenIds, address recipient, bytes calldata extraData) external;
}

/* Seaport structs, for reference, used in offer/consideration above */
// enum ItemType {
//     NATIVE,
//     ERC20,
//     ERC721,
//     ERC1155
// }

// struct OfferItem {
//     ItemType itemType;
//     address token;
//     uint256 identifierOrCriteria;
//     uint256 startAmount;
//     uint256 endAmount;
// }

// struct ConsiderationItem {
//     ItemType itemType;
//     address token;
//     uint256 identifierOrCriteria;
//     uint256 startAmount;
//     uint256 endAmount;
//     address payable recipient;
// }

// struct SpentItem {
//     ItemType itemType;
//     address token;
//     uint256 identifier;
//     uint256 amount;
// }
