// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {SIP15Encoder, Substandard5Comparison} from '../../src/sips/SIP15Encoder.sol';
import {ZoneParameters} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {
  ConsiderationItemLib,
  OfferItemLib,
  OrderComponentsLib,
  OrderParametersLib,
  OrderLib
} from 'seaport-sol/src/lib/SeaportStructLib.sol';

import {
  ConsiderationItem,
  OrderParameters,
  ItemType,
  OfferItem,
  Order,
  OrderComponents,
  OrderType
} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';
import {CreateZoneParams} from './CreateZoneParams.sol';

contract SIP15Encoder_Unit_test is CreateZoneParams {
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

  function test_EncodeSubstandard1EfficientFuzz(Context memory context) public view {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    this.encodeSubstandard1Efficient(zoneParams, context.fuzzInputs.traitKey);
  }

  function test_EncodeSubstandard1(Context memory context) public view {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    this.encodeSubstandard1(
      zoneParams, context.fuzzInputs.comparisonEnum, context.fuzzInputs.traitValue, context.fuzzInputs.traitKey
    );
  }

  function test_EncodeSubstandard2(Context memory context) public view {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    this.encodeSubstandard1(
      zoneParams, context.fuzzInputs.comparisonEnum, context.fuzzInputs.traitValue, context.fuzzInputs.traitKey
    );
  }

  function test_EncodeSubstandard3(Context memory context) public view {
    this.encodeSubstandard3(
      context.fuzzInputs.comparisonEnum,
      context.fuzzInputs.token,
      context.fuzzInputs.tokenId,
      context.fuzzInputs.traitValue,
      context.fuzzInputs.traitKey
    );
  }

  function test_EncodeSubstandarad5(Context memory context) public view {
    this.encodeSubstandard5(
      context.fuzzInputs.comparisonEnum,
      context.fuzzInputs.token,
      context.fuzzInputs.token2,
      context.fuzzInputs.tokenId,
      context.fuzzInputs.traitValue,
      context.fuzzInputs.traitKey
    );
  }

  function encodeSubstandard1Efficient(ZoneParameters calldata zoneParams, bytes32 _traitKey) public view {
    bytes memory encodedData = SIP15Encoder.encodeSubstandard1Efficient(zoneParams, _traitKey);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));

    bytes memory trimmedData = this.trimSubstandard(encodedData);

    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey) =
      abi.decode(trimmedData, (uint8, address, uint256, bytes32, bytes32));
    assertEq(substandard, 1);
    assertEq(comparisonEnum, 0);
    assertEq(traitKey, _traitKey);
    assertEq(traitValue, bytes32(0));
    assertEq(token, zoneParams.consideration[0].token);
    assertEq(id, zoneParams.consideration[0].identifier);
  }

  function encodeSubstandard1(
    ZoneParameters calldata zoneParams,
    uint8 _comparisonEnum,
    bytes32 _traitValue,
    bytes32 _traitKey
  ) public view {
    bytes memory encodedData = SIP15Encoder.encodeSubstandard1(zoneParams, _comparisonEnum, _traitValue, _traitKey);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));

    bytes memory trimmedData = this.trimSubstandard(encodedData);
    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey) =
      abi.decode(trimmedData, (uint8, address, uint256, bytes32, bytes32));

    assertEq(substandard, 1);
    assertEq(comparisonEnum, _comparisonEnum);
    assertEq(traitKey, _traitKey);
    assertEq(traitValue, _traitValue);
    assertEq(token, zoneParams.offer[0].token);
    assertEq(id, zoneParams.offer[0].identifier);
  }

  function encodeSubstandard2(
    ZoneParameters calldata zoneParams,
    uint8 _comparisonEnum,
    bytes32 _traitValue,
    bytes32 _traitKey
  ) public view {
    bytes memory encodedData = SIP15Encoder.encodeSubstandard1(zoneParams, _comparisonEnum, _traitValue, _traitKey);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));

    bytes memory trimmedData = this.trimSubstandard(encodedData);
    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitValue, bytes32 traitKey) =
      abi.decode(trimmedData, (uint8, address, uint256, bytes32, bytes32));

    assertEq(substandard, 1);
    assertEq(comparisonEnum, _comparisonEnum);
    assertEq(traitKey, _traitKey);
    assertEq(traitValue, _traitValue);
    assertEq(token, zoneParams.consideration[0].token);
    assertEq(id, zoneParams.consideration[0].identifier);
  }

  function encodeSubstandard3(
    uint8 _comparisonEnum,
    address _token,
    uint256 _identifier,
    bytes32 _traitValue,
    bytes32 _traitKey
  ) public view {
    bytes memory encodedData =
      SIP15Encoder.encodeSubstandard3(_comparisonEnum, _token, _identifier, _traitValue, _traitKey);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));

    bytes memory trimmedData = this.trimSubstandard(encodedData);
    (uint8 comparisonEnum, address token, uint256 identifier, bytes32 traitValue, bytes32 traitKey) =
      abi.decode(trimmedData, (uint8, address, uint256, bytes32, bytes32));

    assertEq(substandard, 3);
    assertEq(comparisonEnum, _comparisonEnum);
    assertEq(traitKey, _traitKey);
    assertEq(traitValue, _traitValue);
    assertEq(token, _token);
    assertEq(identifier, _identifier);
  }

  function encodeSubstandard5(
    uint8 _comparisonEnum,
    address _token,
    address _traits,
    uint256 _identifier,
    bytes32 _traitValue,
    bytes32 _traitKey
  ) public view {
    uint8[] memory _compEnums = new uint8[](2);
    _compEnums[0] = _comparisonEnum;
    _compEnums[1] = 70;
    bytes32[] memory _traitValues = new bytes32[](2);
    _traitValues[0] = _traitValue;
    _traitValues[1] = bytes32(uint256(70));

    bytes32[] memory _traitKeys = new bytes32[](2);
    _traitKeys[0] = _traitKey;
    _traitKeys[1] = bytes32(uint256(421));

    Substandard5Comparison memory comparison = Substandard5Comparison({
      comparisonEnums: _compEnums,
      token: _token,
      traits: _traits,
      identifier: _identifier,
      traitValues: _traitValues,
      traitKeys: _traitKeys
    });
    bytes memory encodedData = SIP15Encoder.encodeSubstandard5(comparison);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));
    bytes memory trimmedData = this.trimSubstandard(encodedData);
    (Substandard5Comparison memory returnComp) = abi.decode(trimmedData, (Substandard5Comparison));

    assertEq(substandard, 5);
    assertEq(returnComp.comparisonEnums[0], _comparisonEnum);
    assertEq(returnComp.traitKeys[0], _traitKey);
    assertEq(returnComp.traitValues[0], _traitValue);
    assertEq(returnComp.token, _token);
    assertEq(returnComp.identifier, _identifier);
  }

  function trimSubstandard(bytes calldata dataToTrim) external pure returns (bytes memory data) {
    data = dataToTrim[1:];
  }

  function decodeSubstandardVersion(
    bytes calldata extraData,
    uint256 sipDataStartRelativeOffset
  ) external pure returns (bytes1 versionByte) {
    assembly {
      versionByte := shr(248, calldataload(add(extraData.offset, sipDataStartRelativeOffset)))
      versionByte := or(versionByte, iszero(versionByte))
      versionByte := shl(248, versionByte)
    }
  }
  //use fuzz inputs to create some zone params to test the encoder.
}
