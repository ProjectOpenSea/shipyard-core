// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {ZoneParameters} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {SIP15Encoder, Substandard5Comparison} from '../../src/sips/SIP15Encoder.sol';
import {
  ConsiderationItemLib,
  OfferItemLib,
  OrderComponentsLib,
  OrderParametersLib,
  OrderLib,
  SeaportArrays
} from 'seaport-sol/src/lib/SeaportStructLib.sol';
import {Test, console} from 'forge-std/Test.sol';
import {
  AdvancedOrder,
  ConsiderationItem,
  CriteriaResolver,
  OrderParameters,
  ItemType,
  OfferItem,
  Order,
  SpentItem,
  ReceivedItem,
  OrderComponents,
  OrderType
} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';

contract CreateZoneParams is Test {
  using OfferItemLib for OfferItem;
  using OfferItemLib for OfferItem[];
  using ConsiderationItemLib for ConsiderationItem;
  using ConsiderationItemLib for ConsiderationItem[];
  using OrderComponentsLib for OrderComponents;
  using OrderParametersLib for OrderParameters;
  using OrderLib for Order;
  using OrderLib for Order[];

  string constant SINGLE_721 = 'single 721';
  string constant SINGLE_721_Order = '721 order';

  struct Context {
    ConsiderationInterface seaport;
    FuzzInputs fuzzInputs;
  }

  struct FuzzInputs {
    uint256 tokenId;
    uint256 tokenId2;
    uint128 amount;
    address token;
    address token2;
    address erc20;
    address offerer;
    address recipient;
    bytes32 zoneHash;
    uint256 salt;
    address fulfiller;
    address seaport;
    bytes32 traitKey;
    bytes32 traitValue;
    uint8 comparisonEnum;
  }

  function _createZoneParams(Context memory context) internal view returns (ZoneParameters memory zoneParameters) {
    // Avoid weird overflow issues.
    context.fuzzInputs.amount = uint128(bound(context.fuzzInputs.amount, 1, 0xffffffffffffffff));
    context.fuzzInputs.tokenId = bound(context.fuzzInputs.tokenId, 0, 0xfffffffff);
    //create offer item array from fuzz inputs
    OfferItem[] memory offerItemArray = _createOfferArray(context.fuzzInputs);
    //create consideration item array from fuzz inputs
    ConsiderationItem[] memory considerationItemArray = _createConsiderationArray(context.fuzzInputs);
    //create order components from fuzz inputs
    OrderComponents memory orderComponents =
      _buildOrderComponents(context.fuzzInputs, offerItemArray, considerationItemArray);
    //create order
    Order memory order = OrderLib.empty().withParameters(orderComponents.toOrderParameters());

    //create advanced order
    AdvancedOrder memory advancedOrder = order.toAdvancedOrder(1, 1, bytes(''));

    CriteriaResolver[] memory criteriaResolvers = new CriteriaResolver[](0);
    //create zone parameters
    zoneParameters = _getZoneParameters(advancedOrder, context.fuzzInputs.fulfiller, criteriaResolvers);
  }

  function _createOfferArray(FuzzInputs memory _fuzzInputs) internal view returns (OfferItem[] memory _offerItems) {
    _offerItems = SeaportArrays.OfferItems(
      OfferItemLib.fromDefault(SINGLE_721).withToken(address(_fuzzInputs.token)).withIdentifierOrCriteria(
        _fuzzInputs.tokenId
      ),
      OfferItemLib.fromDefault(SINGLE_721).withToken(address(_fuzzInputs.token2)).withIdentifierOrCriteria(
        _fuzzInputs.tokenId % 7
      )
    );
  }

  function _createConsiderationArray(FuzzInputs memory _fuzzInputs)
    internal
    view
    returns (ConsiderationItem[] memory _considerationItemArray)
  {
    ConsiderationItem memory erc721ConsiderationItem = ConsiderationItemLib.fromDefault(SINGLE_721)
      .withIdentifierOrCriteria(_fuzzInputs.tokenId).withToken(_fuzzInputs.token).withStartAmount(1).withEndAmount(1)
      .withRecipient(_fuzzInputs.recipient);

    // Create a native consideration item.
    ConsiderationItem memory nativeConsiderationItem = ConsiderationItemLib.empty().withItemType(ItemType.NATIVE)
      .withIdentifierOrCriteria(0).withStartAmount(_fuzzInputs.amount).withEndAmount(_fuzzInputs.amount).withRecipient(
      _fuzzInputs.recipient
    );

    // Create a ERC20 consideration item.
    ConsiderationItem memory erc20ConsiderationItemOne = ConsiderationItemLib.empty().withItemType(ItemType.ERC20)
      .withToken(_fuzzInputs.erc20).withIdentifierOrCriteria(0).withStartAmount(_fuzzInputs.amount).withEndAmount(
      _fuzzInputs.amount
    ).withRecipient(_fuzzInputs.recipient);
    // create consideration array
    _considerationItemArray =
      SeaportArrays.ConsiderationItems(erc721ConsiderationItem, nativeConsiderationItem, erc20ConsiderationItemOne);
  }

  function _buildOrderComponents(
    FuzzInputs memory _fuzzInputs,
    OfferItem[] memory offerItemArray,
    ConsiderationItem[] memory considerationItemArray
  ) internal view returns (OrderComponents memory _orderComponents) {
    // Create the offer and consideration item arrays.
    OfferItem[] memory _offerItemArray = offerItemArray;
    ConsiderationItem[] memory _considerationItemArray = considerationItemArray;

    // Build the OrderComponents for the prime offerer's order.
    _orderComponents = OrderComponentsLib.fromDefault(SINGLE_721_Order).withOffer(_offerItemArray).withConsideration(
      _considerationItemArray
    ).withZone(address(1)).withOfferer(_fuzzInputs.offerer).withZone(address(2)).withOrderType(
      OrderType.FULL_RESTRICTED
    ).withZoneHash(_fuzzInputs.zoneHash);
  }

  function _getZoneParameters(
    AdvancedOrder memory advancedOrder,
    address fulfiller,
    CriteriaResolver[] memory criteriaResolvers
  ) internal view returns (ZoneParameters memory zoneParameters) {
    // Get orderParameters from advancedOrder
    OrderParameters memory orderParameters = advancedOrder.parameters;

    // crate arbitrary orderHash
    bytes32 orderHash = keccak256(abi.encode(advancedOrder));

    (SpentItem[] memory spentItems, ReceivedItem[] memory receivedItems) =
      orderParameters.getSpentAndReceivedItems(advancedOrder.numerator, advancedOrder.denominator, 0, criteriaResolvers);
    // Store orderHash in orderHashes array to pass into zoneParameters
    bytes32[] memory orderHashes = new bytes32[](1);
    orderHashes[0] = orderHash;

    // Create ZoneParameters and add to zoneParameters array
    zoneParameters = ZoneParameters({
      orderHash: orderHash,
      fulfiller: fulfiller,
      offerer: orderParameters.offerer,
      offer: spentItems,
      consideration: receivedItems,
      extraData: advancedOrder.extraData,
      orderHashes: orderHashes,
      startTime: orderParameters.startTime,
      endTime: orderParameters.endTime,
      zoneHash: orderParameters.zoneHash
    });
  }
}
