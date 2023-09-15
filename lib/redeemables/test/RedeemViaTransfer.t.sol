// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Solarray} from "solarray/Solarray.sol";
import {BaseOrderTest} from "./utils/BaseOrderTest.sol";
import {TestERC20} from "./utils/mocks/TestERC20.sol";
import {TestERC721} from "./utils/mocks/TestERC721.sol";
import {
    OfferItem,
    ConsiderationItem,
    SpentItem,
    AdvancedOrder,
    OrderParameters,
    CriteriaResolver,
    FulfillmentComponent
} from "seaport-types/src/lib/ConsiderationStructs.sol";
// import {CriteriaResolutionErrors} from "seaport-types/src/interfaces/CriteriaResolutionErrors.sol";
import {ItemType, OrderType, Side} from "seaport-sol/src/SeaportEnums.sol";
import {OfferItemLib, ConsiderationItemLib, OrderParametersLib} from "seaport-sol/src/SeaportSol.sol";
import {RedeemableContractOfferer} from "../src/RedeemableContractOfferer.sol";
import {CampaignParams} from "../src/lib/RedeemableStructs.sol";
import {RedeemableErrorsAndEvents} from "../src/lib/RedeemableErrorsAndEvents.sol";
import {ERC721RedemptionMintable} from "../src/lib/ERC721RedemptionMintable.sol";
import {Merkle} from "../lib/murky/src/Merkle.sol";

contract TestRedeemableContractOfferer is BaseOrderTest, RedeemableErrorsAndEvents {
    using OrderParametersLib for OrderParameters;

    error InvalidContractOrder(bytes32 orderHash);

    RedeemableContractOfferer offerer;
    TestERC721 redeemableToken;
    ERC721RedemptionMintable redemptionToken;
    CriteriaResolver[] criteriaResolvers;
    Merkle merkle = new Merkle();

    address constant _BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    function setUp() public override {
        super.setUp();
        offerer = new RedeemableContractOfferer(
            address(conduit),
            conduitKey,
            address(seaport)
        );
        redeemableToken = new TestERC721();
        redemptionToken = new ERC721RedemptionMintable(
            address(offerer),
            address(redeemableToken)
        );
        vm.label(address(redeemableToken), "redeemableToken");
        vm.label(address(redemptionToken), "redemptionToken");
    }

    function testRedeemWith721SafeTransferFrom() public {
        uint256 tokenId = 2;
        redeemableToken.mint(address(this), tokenId);

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
            endTime: uint32(block.timestamp + 1000),
            maxCampaignRedemptions: 5,
            manager: address(this)
        });

        offerer.createCampaign(params, "");

        OfferItem[] memory offerFromEvent = new OfferItem[](1);
        offerFromEvent[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: address(redemptionToken),
            identifierOrCriteria: tokenId,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
        considerationFromEvent[0] = ConsiderationItem({
            itemType: ItemType.ERC721,
            token: address(redeemableToken),
            identifierOrCriteria: tokenId,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        uint256 campaignId = 1;
        bytes32 redemptionHash = bytes32(0);
        bytes memory extraData = abi.encode(campaignId, redemptionHash);

        // TODO: validate OrderFulfilled event
        bytes memory data = abi.encode(campaignId, redemptionHash);
        redeemableToken.safeTransferFrom(address(this), address(offerer), tokenId, extraData);

        assertEq(redeemableToken.ownerOf(tokenId), _BURN_ADDRESS);
        assertEq(redemptionToken.ownerOf(tokenId), address(this));
    }
}
