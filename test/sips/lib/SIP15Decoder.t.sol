// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {Test, console} from 'forge-std/Test.sol';
import {SIP15Encoder, Substandard5Comparison} from '../../src/sips/SIP15Encoder.sol';
import {SIP15Decoder} from '../../src/sips/SIP15Decoder.sol';
import {ZoneParameters, Schema} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {
  ConsiderationItemLib,
  FulfillmentComponentLib,
  FulfillmentLib,
  OfferItemLib,
  ZoneParametersLib,
  OrderComponentsLib,
  OrderParametersLib,
  AdvancedOrderLib,
  OrderLib,
  SeaportArrays
} from 'seaport-sol/src/lib/SeaportStructLib.sol';

import {
  AdvancedOrder,
  ConsiderationItem,
  CriteriaResolver,
  Fulfillment,
  FulfillmentComponent,
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
import {CreateZoneParams} from './CreateZoneParams.sol';

contract SIP15Decoder_Unit_test is CreateZoneParams {
  using OfferItemLib for OfferItem;
  using OfferItemLib for OfferItem[];
  using ConsiderationItemLib for ConsiderationItem;
  using ConsiderationItemLib for ConsiderationItem[];
  using OrderComponentsLib for OrderComponents;
  using OrderParametersLib for OrderParameters;
  using OrderLib for Order;
  using OrderLib for Order[];

  function setUp() public {
    // create a default offerItem for a single 721;
    // note that it does not have token or identifier set
    OfferItemLib.empty().withItemType(ItemType.ERC721).withStartAmount(1).withEndAmount(1).saveDefault(SINGLE_721);

    ConsiderationItemLib.empty().withItemType(ItemType.ERC721).withStartAmount(1).withEndAmount(1).saveDefault(
      SINGLE_721
    );

    OrderComponentsLib.empty().withOrderType(OrderType.FULL_RESTRICTED).withStartTime(block.timestamp).withEndTime(
      block.timestamp + 10
    ).withSalt(0).saveDefault(SINGLE_721_Order);
  }

  function test_DecodeSubstandard1EfficientFuzz(Context memory context) public {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    bytes memory encodedData = SIP15Encoder.encodeSubstandard1Efficient(zoneParams, context.fuzzInputs.traitKey);
    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey) =
      this.decodeSubstandard1Efficient(encodedData);
    assertEq(comparisonEnum, 0);
    assertEq(traitKey, context.fuzzInputs.traitKey);
    assertEq(traitValue, bytes32(0));
    assertEq(token, zoneParams.consideration[0].token);
    assertEq(id, zoneParams.consideration[0].identifier);
  }

  function test_DecodeSubstandard1Fuzz(Context memory context) public {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    bytes memory encodedData = SIP15Encoder.encodeSubstandard1(
      zoneParams, context.fuzzInputs.comparisonEnum, context.fuzzInputs.traitValue, context.fuzzInputs.traitKey
    );
    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey) =
      this.decodeSubstandard1(encodedData);
    assertEq(comparisonEnum, context.fuzzInputs.comparisonEnum);
    assertEq(traitKey, context.fuzzInputs.traitKey);
    assertEq(traitValue, context.fuzzInputs.traitValue);
    assertEq(token, zoneParams.offer[0].token);
    assertEq(id, zoneParams.offer[0].identifier);
  }

  function test_DecodeSubstandard2Fuzz(Context memory context) public {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    bytes memory encodedData = SIP15Encoder.encodeSubstandard2(
      zoneParams, context.fuzzInputs.comparisonEnum, context.fuzzInputs.traitValue, context.fuzzInputs.traitKey
    );
    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey) =
      this.decodeSubstandard2(encodedData);
    assertEq(comparisonEnum, context.fuzzInputs.comparisonEnum);
    assertEq(traitKey, context.fuzzInputs.traitKey);
    assertEq(traitValue, context.fuzzInputs.traitValue);
    assertEq(token, zoneParams.consideration[0].token);
    assertEq(id, zoneParams.consideration[0].identifier);
  }

  function test_DecodeSubstandard3Fuzz(Context memory context) public {
    bytes memory encodedData = SIP15Encoder.encodeSubstandard3(
      context.fuzzInputs.comparisonEnum,
      context.fuzzInputs.token,
      context.fuzzInputs.tokenId,
      context.fuzzInputs.traitValue,
      context.fuzzInputs.traitKey
    );
    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey) =
      this.decodeSubstandard3(encodedData);
    assertEq(comparisonEnum, context.fuzzInputs.comparisonEnum);
    assertEq(traitKey, context.fuzzInputs.traitKey);
    assertEq(traitValue, context.fuzzInputs.traitValue);
    assertEq(token, context.fuzzInputs.token);
    assertEq(id, context.fuzzInputs.tokenId);
  }

  function test_DecodeSubstandard4Fuzz(Context memory context) public {
    uint256[] memory tokenIds = new uint256[](2);
    tokenIds[0] = context.fuzzInputs.tokenId;
    tokenIds[1] = context.fuzzInputs.tokenId2;

    bytes memory encodedData = SIP15Encoder.encodeSubstandard4(
      context.fuzzInputs.comparisonEnum,
      context.fuzzInputs.token,
      tokenIds,
      context.fuzzInputs.traitValue,
      context.fuzzInputs.traitKey
    );
    (uint8 comparisonEnum, address token, uint256[] memory ids, bytes32 traitValue, bytes32 traitKey) =
      this.decodeSubstandard4(encodedData);
    assertEq(comparisonEnum, context.fuzzInputs.comparisonEnum);
    assertEq(traitKey, context.fuzzInputs.traitKey);
    assertEq(traitValue, context.fuzzInputs.traitValue);
    assertEq(token, context.fuzzInputs.token);
    assertEq(ids[0], context.fuzzInputs.tokenId);
    assertEq(ids[1], context.fuzzInputs.tokenId2);
  }

  function test_DecodeSubstandard5Fuzz(Context memory context) public {
    uint8[] memory _compEnums = new uint8[](2);
    _compEnums[0] = context.fuzzInputs.comparisonEnum;
    _compEnums[1] = 70;
    bytes32[] memory _traitValues = new bytes32[](2);
    _traitValues[0] = context.fuzzInputs.traitValue;
    _traitValues[1] = bytes32(uint256(70));

    bytes32[] memory _traitKeys = new bytes32[](2);
    _traitKeys[0] = context.fuzzInputs.traitKey;
    _traitKeys[1] = bytes32(uint256(421));

    Substandard5Comparison memory comparison = Substandard5Comparison({
      comparisonEnums: _compEnums,
      token: context.fuzzInputs.token,
      traits: context.fuzzInputs.token2,
      identifier: context.fuzzInputs.tokenId,
      traitValues: _traitValues,
      traitKeys: _traitKeys
    });

    bytes memory encodedData = SIP15Encoder.encodeSubstandard5(comparison);

    (Substandard5Comparison memory substandard5Comparison) = this.decodeSubstandard5(encodedData);
    assertEq(substandard5Comparison.comparisonEnums[0], context.fuzzInputs.comparisonEnum);
    assertEq(substandard5Comparison.comparisonEnums[1], 70);
    assertEq(substandard5Comparison.traitKeys[0], context.fuzzInputs.traitKey);
    assertEq(substandard5Comparison.traitValues[0], context.fuzzInputs.traitValue);
    assertEq(substandard5Comparison.traitKeys[1], bytes32(uint256(421)));
    assertEq(substandard5Comparison.traitValues[1], bytes32(uint256(70)));
    assertEq(substandard5Comparison.token, context.fuzzInputs.token);
    assertEq(substandard5Comparison.identifier, context.fuzzInputs.tokenId);
    assertEq(substandard5Comparison.traits, context.fuzzInputs.token2);
  }

  function decodeSubstandard1Efficient(bytes calldata encodedData)
    external
    pure
    returns (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey)
  {
    return SIP15Decoder.decodeSubstandard1Efficient(encodedData);
  }

  function decodeSubstandard1(bytes calldata encodedData)
    external
    pure
    returns (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey)
  {
    return SIP15Decoder.decodeSubstandard1(encodedData);
  }

  function decodeSubstandard2(bytes calldata encodedData)
    external
    pure
    returns (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey)
  {
    return SIP15Decoder.decodeSubstandard2(encodedData);
  }

  function decodeSubstandard3(bytes calldata encodedData)
    external
    pure
    returns (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey)
  {
    return SIP15Decoder.decodeSubstandard3(encodedData);
  }

  function decodeSubstandard4(bytes calldata encodedData)
    external
    pure
    returns (uint8 comparisonEnum, address token, uint256[] memory ids, bytes32 traitValue, bytes32 traitKey)
  {
    return SIP15Decoder.decodeSubstandard4(encodedData);
  }

  function decodeSubstandard5(bytes calldata encodedData)
    external
    pure
    returns (Substandard5Comparison memory substandard5Comparison)
  {
    return SIP15Decoder.decodeSubstandard5(encodedData);
  }
}
