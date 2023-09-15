// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {RedeemableContractOfferer} from "../src/RedeemableContractOfferer.sol";
import {CampaignParams} from "../src/lib/RedeemableStructs.sol";
import {ERC721RedemptionMintable} from "../src/lib/ERC721RedemptionMintable.sol";
import {TestERC721} from "../test/utils/mocks/TestERC721.sol";

contract DeployAndConfigureExampleCampaign is Script {
    // Addresses: Seaport
    address seaport = 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC;
    address conduit = 0x1E0049783F008A0085193E00003D00cd54003c71;
    bytes32 conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;

    address constant _BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    function run() external {
        vm.startBroadcast();

        RedeemableContractOfferer offerer = new RedeemableContractOfferer(
            conduit,
            conduitKey,
            seaport
        );
        TestERC721 redeemableToken = new TestERC721();
        ERC721RedemptionMintable redemptionToken = new ERC721RedemptionMintable(
            address(offerer),
            address(redeemableToken)
        );

        // Configure the campaign.
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        CampaignParams memory params = CampaignParams({
            offer: offer,
            consideration: consideration,
            signer: address(0),
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp + 1_000_000),
            maxCampaignRedemptions: 1_000,
            manager: msg.sender
        });
        offerer.createCampaign(params, "ipfs://QmdChMVnMSq4U6oVKhud7wUSEZGnwuMuTY5rUQx57Ayp6H");

        // Mint tokens 1 and 5 to redeem for tokens 1 and 5.
        redeemableToken.mint(msg.sender, 1);
        redeemableToken.mint(msg.sender, 5);

        // Let's redeem them!
        uint256 campaignId = 1;
        bytes32 redemptionHash = bytes32(0);
        bytes memory data = abi.encode(campaignId, redemptionHash);
        redeemableToken.safeTransferFrom(msg.sender, address(offerer), 1, data);
        redeemableToken.safeTransferFrom(msg.sender, address(offerer), 5, data);
    }
}
