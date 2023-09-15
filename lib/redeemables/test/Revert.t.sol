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

    function testRevertRedeemWithCriteriaResolversViaSeaport() public {
        uint256 tokenId = 7;
        redeemableToken.mint(address(this), tokenId);
        redeemableToken.setApprovalForAll(address(conduit), true);

        CriteriaResolver[] memory resolvers = new CriteriaResolver[](1);

        // Create an array of hashed identifiers (0-4)
        // Get the merkle root of the hashed identifiers to pass into updateCampaign
        // Only tokenIds 0-4 can be redeemed
        bytes32[] memory hashedIdentifiers = new bytes32[](5);
        for (uint256 i = 0; i < hashedIdentifiers.length; i++) {
            hashedIdentifiers[i] = keccak256(abi.encode(i));
        }
        bytes32 root = merkle.getRoot(hashedIdentifiers);

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        // Contract offerer will only consider tokenIds 0-4
        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: uint256(root),
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        {
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
        }

        {
            // Hash identifiers 5 - 9 and create invalid merkle root
            // to pass into consideration
            for (uint256 i = 0; i < hashedIdentifiers.length; i++) {
                hashedIdentifiers[i] = keccak256(abi.encode(i + 5));
            }
            root = merkle.getRoot(hashedIdentifiers);
            consideration[0].identifierOrCriteria = uint256(root);

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

            assertGt(uint256(consideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            bytes memory extraData = abi.encode(1, bytes32(0)); // campaignId, redemptionHash

            OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
                OrderType.CONTRACT
            ).withConsideration(consideration).withOffer(offer).withConduitKey(conduitKey).withStartTime(
                block.timestamp
            ).withEndTime(block.timestamp + 1).withTotalOriginalConsiderationItems(consideration.length);
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            resolvers[0] = CriteriaResolver({
                orderIndex: 0,
                side: Side.CONSIDERATION,
                index: 0,
                identifier: tokenId,
                criteriaProof: merkle.getProof(hashedIdentifiers, 2)
            });

            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidContractOrder.selector,
                    (uint256(uint160(address(offerer))) << 96) + seaport.getContractOffererNonce(address(offerer))
                )
            );
            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: resolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });
        }
    }

    function testRevertmaxCampaignRedemptionsReached() public {
        redeemableToken.mint(address(this), 0);
        redeemableToken.mint(address(this), 1);
        redeemableToken.mint(address(this), 2);
        redeemableToken.setApprovalForAll(address(conduit), true);

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

        {
            CampaignParams memory params = CampaignParams({
                offer: offer,
                consideration: consideration,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 2,
                manager: address(this)
            });

            offerer.createCampaign(params, "");
        }

        {
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionToken),
                identifierOrCriteria: 0,
                startAmount: 1,
                endAmount: 1
            });
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableToken),
                identifierOrCriteria: 0,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionToken),
                identifierOrCriteria: 1,
                startAmount: 1,
                endAmount: 1
            });

            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableToken),
                identifierOrCriteria: 1,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            assertGt(uint256(consideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            bytes memory extraData = abi.encode(1, bytes32(0)); // campaignId, redemptionHash

            considerationFromEvent[0].identifierOrCriteria = 0;

            OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
                OrderType.CONTRACT
            ).withConsideration(considerationFromEvent).withOffer(offer).withConduitKey(conduitKey).withStartTime(
                block.timestamp
            ).withEndTime(block.timestamp + 1).withTotalOriginalConsiderationItems(consideration.length);
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            considerationFromEvent[0].identifierOrCriteria = 1;

            // vm.expectEmit(true, true, true, true);
            // emit Or(
            //     address(this),
            //     campaignId,
            //     ConsiderationItemLib.toSpentItemArray(considerationFromEvent),
            //     OfferItemLib.toSpentItemArray(offerFromEvent),
            //     redemptionHash
            // );

            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            considerationFromEvent[0].identifierOrCriteria = 2;

            // Should revert on the third redemption
            // The call to Seaport should revert with maxCampaignRedemptionsReached(3, 2)
            // vm.expectRevert(
            //     abi.encodeWithSelector(
            //         maxCampaignRedemptionsReached.selector,
            //         3,
            //         2
            //     )
            // );
            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidContractOrder.selector,
                    (uint256(uint160(address(offerer))) << 96) + seaport.getContractOffererNonce(address(offerer))
                )
            );
            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            assertEq(redeemableToken.ownerOf(0), _BURN_ADDRESS);
            assertEq(redeemableToken.ownerOf(1), _BURN_ADDRESS);
            assertEq(redemptionToken.ownerOf(0), address(this));
            assertEq(redemptionToken.ownerOf(1), address(this));
        }
    }

    function testRevertConsiderationItemRecipientCannotBeZeroAddress() public {
        uint256 tokenId = 2;
        redeemableToken.mint(address(this), tokenId);
        redeemableToken.setApprovalForAll(address(conduit), true);

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
            recipient: payable(address(0))
        });

        {
            CampaignParams memory params = CampaignParams({
                offer: offer,
                consideration: consideration,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 5,
                manager: address(this)
            });

            vm.expectRevert(abi.encodeWithSelector(ConsiderationItemRecipientCannotBeZeroAddress.selector));
            offerer.createCampaign(params, "");
        }
    }
}
