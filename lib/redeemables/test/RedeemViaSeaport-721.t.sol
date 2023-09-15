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
import {ItemType, OrderType, Side} from "seaport-sol/src/SeaportEnums.sol";
import {MockERC721DynamicTraits} from "./utils/mocks/MockERC721DynamicTraits.sol";
import {OfferItemLib, ConsiderationItemLib, OrderParametersLib} from "seaport-sol/src/SeaportSol.sol";
import {RedeemableContractOfferer} from "../src/RedeemableContractOfferer.sol";
import {CampaignParams, TraitRedemption} from "../src/lib/RedeemableStructs.sol";
import {RedeemableErrorsAndEvents} from "../src/lib/RedeemableErrorsAndEvents.sol";
import {ERC721RedemptionMintable} from "../src/lib/ERC721RedemptionMintable.sol";
import {ERC721RedemptionMintableWithCounter} from "../src/lib/ERC721RedemptionMintableWithCounter.sol";
import {Merkle} from "../lib/murky/src/Merkle.sol";

contract RedeemViaSeaport721 is BaseOrderTest, RedeemableErrorsAndEvents {
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

    function testRedeemWithSeaport() public {
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

        // uint256 campaignId = 1;
        // bytes32 redemptionHash = bytes32(0);

        {
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
            consideration[0].identifierOrCriteria = tokenId;

            // TODO: validate OrderFulfilled event
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

            // {
            //     bytes
            //     vm.expectEmit(true, true, true, true);
            //     emit OrderFulfilled();
            // }

            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            assertEq(redeemableToken.ownerOf(tokenId), _BURN_ADDRESS);
            assertEq(redemptionToken.ownerOf(tokenId), address(this));
        }
    }

    // TODO: write test with ETH redemption consideration
    // TODO: 1155 tests with same tokenId (amount > 1), different tokenIds
    // TODO: update erc20 amount to use decimals

    function testRedeemAndSendErc20ToThirdAddressViaSeaport() public {
        uint256 tokenId = 2;
        redeemableToken.mint(address(this), tokenId);
        redeemableToken.setApprovalForAll(address(conduit), true);

        // Deploy the ERC20
        TestERC20 erc20 = new TestERC20();
        uint256 erc20Amount = 10;

        // Mint 100 tokens to the test contract
        erc20.mint(address(this), 100);

        // Approve the conduit to spend tokens
        erc20.approve(address(conduit), type(uint256).max);

        OfferItem[] memory campaignOffer = new OfferItem[](1);
        campaignOffer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory campaignConsideration = new ConsiderationItem[](2);
        campaignConsideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });
        campaignConsideration[1] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(erc20),
            identifierOrCriteria: 0,
            startAmount: erc20Amount,
            endAmount: erc20Amount,
            recipient: payable(eve.addr)
        });

        {
            CampaignParams memory params = CampaignParams({
                offer: campaignOffer,
                consideration: campaignConsideration,
                signer: address(0),
                startTime: uint32(block.timestamp),
                endTime: uint32(block.timestamp + 1000),
                maxCampaignRedemptions: 5,
                manager: address(this)
            });

            offerer.createCampaign(params, "");
        }

        // uint256 campaignId = 1;
        // bytes32 redemptionHash = bytes32(0);

        {
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

            assertGt(uint256(campaignConsideration[0].itemType), uint256(considerationFromEvent[0].itemType));

            bytes memory extraData = abi.encode(1, bytes32(0)); // campaignId, redemptionHash

            campaignConsideration[0].itemType = ItemType.ERC721;
            campaignConsideration[0].identifierOrCriteria = tokenId;

            // TODO: validate OrderFulfilled event
            OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
                OrderType.CONTRACT
            ).withConsideration(campaignConsideration).withOffer(campaignOffer).withConduitKey(conduitKey).withStartTime(
                block.timestamp
            ).withEndTime(block.timestamp + 1).withTotalOriginalConsiderationItems(campaignConsideration.length);
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            uint256 erc20BalanceBefore = erc20.balanceOf(address(this));

            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            assertEq(redeemableToken.ownerOf(tokenId), _BURN_ADDRESS);
            assertEq(redemptionToken.ownerOf(tokenId), address(this));
            assertEq(erc20BalanceBefore - erc20.balanceOf(address(this)), erc20Amount);
            assertEq(erc20.balanceOf(eve.addr), erc20Amount);
        }
    }

    // TODO: add resolved tokenId to extradata
    // TODO: fix redemptionToken being minted with merkle root
    function testRedeemWithCriteriaResolversViaSeaport() public {
        uint256 tokenId = 2;
        redeemableToken.mint(address(this), tokenId);
        redeemableToken.setApprovalForAll(address(conduit), true);

        ERC721RedemptionMintableWithCounter redemptionTokenWithCounter = new ERC721RedemptionMintableWithCounter(
                address(offerer),
                address(redeemableToken)
            );

        CriteriaResolver[] memory resolvers = new CriteriaResolver[](1);

        // Create an array of hashed identifiers (0-4)
        // Only tokenIds 0-4 can be redeemed
        bytes32[] memory hashedIdentifiers = new bytes32[](5);
        for (uint256 i = 0; i < hashedIdentifiers.length; i++) {
            hashedIdentifiers[i] = keccak256(abi.encode(i));
        }
        bytes32 root = merkle.getRoot(hashedIdentifiers);

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionTokenWithCounter),
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
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionTokenWithCounter),
                identifierOrCriteria: 0,
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

            // TODO: validate OrderFulfilled event
            // vm.expectEmit(true, true, true, true);
            // emit OrderFulfilled();

            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: resolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            // TODO: failing because redemptionToken tokenId is merkle root
            assertEq(redeemableToken.ownerOf(tokenId), _BURN_ADDRESS);
            assertEq(redemptionTokenWithCounter.ownerOf(0), address(this));
        }
    }

    // TODO: burn 1, send weth to third address, also redeem trait
    // TODO: mock erc20 to third address or burn
    // TODO: mock erc721 with tokenId counter
    // TODO: make MockErc20RedemptionMintable with mintRedemption
    // TODO: burn nft and send erc20 to third address, get nft and erc20
    // TODO: mintRedemption should return tokenIds array
    // TODO: then add dynamic traits
    // TODO: by EOW, have dynamic traits demo

    // notice: redemptionToken tokenId will be tokenId of first item in consideration
    function testBurn2Redeem1ViaSeaport() public {
        // Set the two tokenIds to be burned
        uint256 burnTokenId0 = 2;
        uint256 burnTokenId1 = 3;

        // Mint two redeemableTokens of tokenId burnTokenId0 and burnTokenId1 to the test contract
        redeemableToken.mint(address(this), burnTokenId0);
        redeemableToken.mint(address(this), burnTokenId1);

        // Approve the conduit to transfer the redeemableTokens on behalf of the test contract
        redeemableToken.setApprovalForAll(address(conduit), true);

        // Create a single-item OfferItem array with the redemption token the caller will receive
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        // Create a single-item ConsiderationItem array and require the caller to burn two redeemableTokens (of any tokenId)
        ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        // Create the CampaignParams with the offer and consideration from above.
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

            // Call createCampaign on the offerer and pass in the CampaignParams
            offerer.createCampaign(params, "");
        }

        // uint256 campaignId = 1;
        // bytes32 redemptionHash = bytes32(0);

        {
            // Create the offer we expect to be emitted in the event
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionToken),
                identifierOrCriteria: burnTokenId0,
                startAmount: 1,
                endAmount: 1
            });

            // Create the consideration we expect to be emitted in the event
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](2);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableToken),
                identifierOrCriteria: burnTokenId0,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            considerationFromEvent[1] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableToken),
                identifierOrCriteria: burnTokenId1,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            // Check that the consideration passed into createCampaign has itemType ERC721_WITH_CRITERIA
            assertEq(uint256(consideration[0].itemType), 4);

            // Check that the consideration emitted in the event has itemType ERC721
            assertEq(uint256(considerationFromEvent[0].itemType), 2);
            assertEq(uint256(considerationFromEvent[1].itemType), 2);

            // Create the extraData to be passed into fulfillAdvancedOrder
            bytes memory extraData = abi.encode(1, bytes32(0)); // campaignId, redemptionHash

            // TODO: validate OrderFulfilled event

            // Create the OrderParameters to be passed into fulfillAdvancedOrder
            OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
                OrderType.CONTRACT
            ).withConsideration(considerationFromEvent).withOffer(offer).withConduitKey(conduitKey).withStartTime(
                block.timestamp
            ).withEndTime(block.timestamp + 1).withTotalOriginalConsiderationItems(considerationFromEvent.length);

            // Create the AdvancedOrder to be passed into fulfillAdvancedOrder
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            // Call fulfillAdvancedOrder
            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            // Check that the two redeemable tokens have been burned
            assertEq(redeemableToken.ownerOf(burnTokenId0), _BURN_ADDRESS);
            assertEq(redeemableToken.ownerOf(burnTokenId1), _BURN_ADDRESS);

            // Check that the redemption token has been minted to the test contract
            assertEq(redemptionToken.ownerOf(burnTokenId0), address(this));
        }
    }

    function testBurn1Redeem2WithSeaport() public {
        // Set the two tokenIds to be redeemed
        uint256 redemptionTokenId0 = 0;
        uint256 redemptionTokenId1 = 1;

        // Set the tokenId to be burned to the first tokenId to be redeemed
        uint256 redeemableTokenId0 = redemptionTokenId0;

        ERC721RedemptionMintableWithCounter redemptionTokenWithCounter = new ERC721RedemptionMintableWithCounter(
                address(offerer),
                address(redeemableToken)
            );

        // Mint a redeemableToken of tokenId redeemableTokenId0 to the test contract
        redeemableToken.mint(address(this), redeemableTokenId0);

        // Approve the conduit to transfer the redeemableTokens on behalf of the test contract
        redeemableToken.setApprovalForAll(address(conduit), true);

        // Create a two-item OfferItem array with the 2 redemptionTokens the caller will receive
        OfferItem[] memory offer = new OfferItem[](2);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionTokenWithCounter),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        offer[1] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionTokenWithCounter),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        // Create a single-item ConsiderationItem array with the redeemableToken the caller will burn
        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        // Create the CampaignParams with the offer and consideration from above.
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

            // Call createCampaign on the offerer and pass in the CampaignParams
            offerer.createCampaign(params, "");
        }

        // uint256 campaignId = 1;
        // bytes32 redemptionHash = bytes32(0);

        {
            // Create the offer we expect to be emitted in the event
            OfferItem[] memory offerFromEvent = new OfferItem[](2);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionTokenWithCounter),
                identifierOrCriteria: redemptionTokenId0,
                startAmount: 1,
                endAmount: 1
            });

            offerFromEvent[1] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionTokenWithCounter),
                identifierOrCriteria: redemptionTokenId1,
                startAmount: 1,
                endAmount: 1
            });

            // Create the consideration we expect to be emitted in the event
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableToken),
                identifierOrCriteria: redeemableTokenId0,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            // Check that the consideration passed into createCampaign has itemType ERC721_WITH_CRITERIA
            assertEq(uint256(consideration[0].itemType), 4);

            // Check that the consideration emitted in the event has itemType ERC721
            assertEq(uint256(considerationFromEvent[0].itemType), 2);

            // Create the extraData to be passed into fulfillAdvancedOrder
            bytes memory extraData = abi.encode(1, bytes32(0)); // campaignId, redemptionHash

            // TODO: validate OrderFulfilled event

            // Create the OrderParameters to be passed into fulfillAdvancedOrder
            OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
                OrderType.CONTRACT
            ).withConsideration(considerationFromEvent).withOffer(offer).withConduitKey(conduitKey).withStartTime(
                block.timestamp
            ).withEndTime(block.timestamp + 1).withTotalOriginalConsiderationItems(considerationFromEvent.length);

            // Create the AdvancedOrder to be passed into fulfillAdvancedOrder
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            // Call fulfillAdvancedOrder
            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            // Check that the redeemableToken has been burned
            assertEq(redeemableToken.ownerOf(redeemableTokenId0), _BURN_ADDRESS);

            // Check that the two redemptionTokens has been minted to the test contract
            assertEq(redemptionTokenWithCounter.ownerOf(redemptionTokenId0), address(this));
            assertEq(redemptionTokenWithCounter.ownerOf(redemptionTokenId1), address(this));
        }
    }

    function testBurn2SeparateRedeemableTokensRedeem1ViaSeaport() public {
        // Set the tokenId to be burned
        uint256 burnTokenId0 = 2;

        // Create the second redeemableToken to be burned
        TestERC721 redeemableTokenTwo = new TestERC721();

        // Mint one redeemableToken ane one redeemableTokenTwo of tokenId burnTokenId0 to the test contract
        redeemableToken.mint(address(this), burnTokenId0);
        redeemableTokenTwo.mint(address(this), burnTokenId0);

        // Approve the conduit to transfer the redeemableTokens on behalf of the test contract
        redeemableToken.setApprovalForAll(address(conduit), true);
        redeemableTokenTwo.setApprovalForAll(address(conduit), true);

        // Create a single-item OfferItem array with the redemption token the caller will receive
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        // Create a two-item ConsiderationItem array and require the caller to burn one redeemableToken and one redeemableTokenTwo (of any tokenId)
        ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableTokenTwo),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        // Create the CampaignParams with the offer and consideration from above.
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

            // Call createCampaign on the offerer and pass in the CampaignParams
            offerer.createCampaign(params, "");
        }

        // uint256 campaignId = 1;
        // bytes32 redemptionHash = bytes32(0);

        {
            // Create the offer we expect to be emitted in the event
            OfferItem[] memory offerFromEvent = new OfferItem[](1);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionToken),
                identifierOrCriteria: burnTokenId0,
                startAmount: 1,
                endAmount: 1
            });

            // Create the consideration we expect to be emitted in the event
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](2);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableToken),
                identifierOrCriteria: burnTokenId0,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            considerationFromEvent[1] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableTokenTwo),
                identifierOrCriteria: burnTokenId0,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            // Check that the consideration passed into createCampaign has itemType ERC721_WITH_CRITERIA
            assertEq(uint256(consideration[0].itemType), 4);

            // Check that the consideration emitted in the event has itemType ERC721
            assertEq(uint256(considerationFromEvent[0].itemType), 2);
            assertEq(uint256(considerationFromEvent[1].itemType), 2);

            // Create the extraData to be passed into fulfillAdvancedOrder
            bytes memory extraData = abi.encode(1, bytes32(0)); // campaignId, redemptionHash

            // TODO: validate OrderFulfilled event

            // Create the OrderParameters to be passed into fulfillAdvancedOrder
            OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
                OrderType.CONTRACT
            ).withConsideration(considerationFromEvent).withOffer(offer).withConduitKey(conduitKey).withStartTime(
                block.timestamp
            ).withEndTime(block.timestamp + 1).withTotalOriginalConsiderationItems(considerationFromEvent.length);

            // Create the AdvancedOrder to be passed into fulfillAdvancedOrder
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            // Call fulfillAdvancedOrder
            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            // Check that one redeemableToken and one redeemableTokenTwo have been burned
            assertEq(redeemableToken.ownerOf(burnTokenId0), _BURN_ADDRESS);
            assertEq(redeemableTokenTwo.ownerOf(burnTokenId0), _BURN_ADDRESS);

            // Check that the redemption token has been minted to the test contract
            assertEq(redemptionToken.ownerOf(burnTokenId0), address(this));
        }
    }

    // TODO: add multi-redeem file

    function testBurn1Redeem2SeparateRedemptionTokensWithSeaport() public {
        // Set the tokenId to be redeemed
        uint256 redemptionTokenId = 2;

        // Set the tokenId to be burned to the first tokenId to be redeemed
        uint256 redeemableTokenId = redemptionTokenId;

        // Create a new ERC721RedemptionMintable redemptionTokenTwo
        ERC721RedemptionMintable redemptionTokenTwo = new ERC721RedemptionMintable(
                address(offerer),
                address(redeemableToken)
            );

        // Mint a redeemableToken of tokenId redeemableTokenId to the test contract
        redeemableToken.mint(address(this), redeemableTokenId);

        // Approve the conduit to transfer the redeemableTokens on behalf of the test contract
        redeemableToken.setApprovalForAll(address(conduit), true);

        // Create a two-item OfferItem array with the one redemptionToken and one redemptionTokenTwo the caller will receive
        OfferItem[] memory offer = new OfferItem[](2);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        offer[1] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionTokenTwo),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        // Create a single-item ConsiderationItem array with the redeemableToken the caller will burn
        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        // Create the CampaignParams with the offer and consideration from above.
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

            // Call createCampaign on the offerer and pass in the CampaignParams
            offerer.createCampaign(params, "");
        }

        // uint256 campaignId = 1;
        // bytes32 redemptionHash = bytes32(0);

        {
            // Create the offer we expect to be emitted in the event
            OfferItem[] memory offerFromEvent = new OfferItem[](2);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionToken),
                identifierOrCriteria: redemptionTokenId,
                startAmount: 1,
                endAmount: 1
            });

            offerFromEvent[1] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionToken),
                identifierOrCriteria: redemptionTokenId,
                startAmount: 1,
                endAmount: 1
            });

            // Create the consideration we expect to be emitted in the event
            ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
            considerationFromEvent[0] = ConsiderationItem({
                itemType: ItemType.ERC721,
                token: address(redeemableToken),
                identifierOrCriteria: redeemableTokenId,
                startAmount: 1,
                endAmount: 1,
                recipient: payable(_BURN_ADDRESS)
            });

            // Check that the consideration passed into createCampaign has itemType ERC721_WITH_CRITERIA
            assertEq(uint256(consideration[0].itemType), 4);

            // Check that the consideration emitted in the event has itemType ERC721
            assertEq(uint256(considerationFromEvent[0].itemType), 2);

            // Create the extraData to be passed into fulfillAdvancedOrder
            bytes memory extraData = abi.encode(1, bytes32(0)); // campaignId, redemptionHash

            // TODO: validate OrderFulfilled event

            // Create the OrderParameters to be passed into fulfillAdvancedOrder
            OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
                OrderType.CONTRACT
            ).withConsideration(considerationFromEvent).withOffer(offer).withConduitKey(conduitKey).withStartTime(
                block.timestamp
            ).withEndTime(block.timestamp + 1).withTotalOriginalConsiderationItems(considerationFromEvent.length);

            // Create the AdvancedOrder to be passed into fulfillAdvancedOrder
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            // Call fulfillAdvancedOrder
            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            // Check that the redeemableToken has been burned
            assertEq(redeemableToken.ownerOf(redeemableTokenId), _BURN_ADDRESS);

            // Check that the two redemptionTokens has been minted to the test contract
            assertEq(redemptionToken.ownerOf(redemptionTokenId), address(this));
            assertEq(redemptionTokenTwo.ownerOf(redemptionTokenId), address(this));
        }
    }

    function xtestDynamicTraitRedemptionViaSeaport() public {
        // Set the tokenId to be redeemed
        uint256 redemptionTokenId0 = 2;

        // Set the tokenId to be burned to the tokenId to be redeemed
        uint256 redeemableTokenId0 = redemptionTokenId0;

        // Deploy the mock ERC721 with dynamic traits
        // Allow the contract offerer to set traits
        MockERC721DynamicTraits dynamicTraitsToken = new MockERC721DynamicTraits(
                address(offerer)
            );

        // Mint a dynamicTraitsToken of tokenId redeemableTokenId0 to the test contract
        dynamicTraitsToken.mint(address(this), redeemableTokenId0);

        // Approve the conduit to transfer the redeemableTokens on behalf of the test contract
        dynamicTraitsToken.setApprovalForAll(address(conduit), true);

        // Create a single-item offer array with the redemptionToken the caller will receive
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        // Create an empty consideration array since the redeemable is a trait redemption
        ConsiderationItem[] memory consideration = new ConsiderationItem[](0);

        // Create the CampaignParams with the offer and consideration from above.
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

            // Call createCampaign on the offerer and pass in the CampaignParams
            offerer.createCampaign(params, "");
        }

        // uint256 campaignId = 1;
        // bytes32 redemptionHash = bytes32(0);

        {
            // Create the offer we expect to be emitted in the event
            OfferItem[] memory offerFromEvent = new OfferItem[](2);
            offerFromEvent[0] = OfferItem({
                itemType: ItemType.ERC721,
                token: address(redemptionToken),
                identifierOrCriteria: redemptionTokenId0,
                startAmount: 1,
                endAmount: 1
            });

            // Check that the consideration passed into createCampaign has itemType ERC721_WITH_CRITERIA
            assertEq(uint256(consideration[0].itemType), 4);

            TraitRedemption memory traitRedemption = TraitRedemption({
                substandard: 0, // set value to traitValue
                token: address(dynamicTraitsToken),
                identifier: redeemableTokenId0,
                traitKey: "isRedeemed",
                traitValue: bytes32(abi.encode(1)),
                substandardValue: bytes32(abi.encode(0))
            });

            // Create the extraData to be passed into fulfillAdvancedOrder
            bytes memory extraData = abi.encode(1, bytes32(0), traitRedemption); // campaignId, redemptionHash

            // TODO: validate OrderFulfilled event

            // Create the OrderParameters to be passed into fulfillAdvancedOrder
            OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
                OrderType.CONTRACT
            ).withConsideration(consideration).withOffer(offer).withConduitKey(conduitKey).withStartTime(
                block.timestamp
            ).withEndTime(block.timestamp + 1).withTotalOriginalConsiderationItems(consideration.length);

            // Create the AdvancedOrder to be passed into fulfillAdvancedOrder
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            // Call fulfillAdvancedOrder
            seaport.fulfillAdvancedOrder({
                advancedOrder: order,
                criteriaResolvers: criteriaResolvers,
                fulfillerConduitKey: conduitKey,
                recipient: address(0)
            });

            // Check that the redeemableToken has been burned
            assertEq(dynamicTraitsToken.ownerOf(redeemableTokenId0), address(this));

            // Check that the two redemptionTokens has been minted to the test contract
            assertEq(redemptionToken.ownerOf(redemptionTokenId0), address(this));
        }
    }

    function xtestRedeemMultipleWithSeaport() public {
        uint256 tokenId;
        redeemableToken.setApprovalForAll(address(conduit), true);

        AdvancedOrder[] memory orders = new AdvancedOrder[](5);
        OfferItem[] memory offer = new OfferItem[](1);
        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);

        uint256 campaignId = 1;
        bytes32 redemptionHash = bytes32(0);

        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        OrderParameters memory parameters = OrderParametersLib.empty().withOfferer(address(offerer)).withOrderType(
            OrderType.CONTRACT
        ).withConsideration(consideration).withOffer(offer).withStartTime(block.timestamp).withEndTime(
            block.timestamp + 1
        ).withTotalOriginalConsiderationItems(1);

        for (uint256 i; i < 5; i++) {
            tokenId = i;
            redeemableToken.mint(address(this), tokenId);

            bytes memory extraData = abi.encode(campaignId, redemptionHash);
            AdvancedOrder memory order = AdvancedOrder({
                parameters: parameters,
                numerator: 1,
                denominator: 1,
                signature: "",
                extraData: extraData
            });

            orders[i] = order;
        }

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
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redemptionToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory considerationFromEvent = new ConsiderationItem[](1);
        considerationFromEvent[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemableToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        (
            FulfillmentComponent[][] memory offerFulfillmentComponents,
            FulfillmentComponent[][] memory considerationFulfillmentComponents
        ) = fulfill.getNaiveFulfillmentComponents(orders);

        seaport.fulfillAvailableAdvancedOrders({
            advancedOrders: orders,
            criteriaResolvers: criteriaResolvers,
            offerFulfillments: offerFulfillmentComponents,
            considerationFulfillments: considerationFulfillmentComponents,
            fulfillerConduitKey: conduitKey,
            recipient: address(0),
            maximumFulfilled: 10
        });

        for (uint256 i; i < 5; i++) {
            tokenId = i;
            assertEq(redeemableToken.ownerOf(tokenId), _BURN_ADDRESS);
            assertEq(redemptionToken.ownerOf(tokenId), address(this));
        }
    }
}
