// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReceivedItem} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {ItemType} from 'seaport-types/src/lib/ConsiderationEnums.sol';
import {ZoneParameters, Schema} from 'seaport-types/src/lib/ConsiderationStructs.sol';

struct Substandard5Comparison {
  uint8[] comparisonEnums;
  address token;
  address traits;
  uint256 identifier;
  bytes32[] traitValues;
  bytes32[] traitKeys;
}

library SIP15Encoder {
  /**
   * @notice Generate a zone hash for an SIP15 contract,
   * @param encodedData the SIP15 encoded extra data
   * @return bytes32 hashed encoded data
   */
  function generateZoneHash(bytes memory encodedData) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(encodedData));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-1 Efficient, which specifies the
   * first consideration item, comparison "equal to", single trait key, zero trait value
   * @param zoneParameters the orderParams of the order to be encoded
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @return bytes the encoded extra data with added substandard
   */
  function encodeSubstandard1Efficient(
    ZoneParameters memory zoneParameters,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    // Get the token address from the first consideration item
    address token = zoneParameters.consideration[0].token;

    // Get the id from the first consideration item
    uint256 id = zoneParameters.consideration[0].identifier;
    return abi.encodePacked(uint8(0x00), abi.encode(0, token, id, bytes32(0), traitKey));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-1, which specifies the
   *         token address and id from first offer item
   * @param zoneParameters the zone parameters with the offer to be used for the token and identifier
   * @param comparisonEnum the comparison enum 0 - 5
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @param traitValue the expected value of the trait.
   * @return bytes the encoded extra data with added substandard
   */
  function encodeSubstandard1(
    ZoneParameters memory zoneParameters,
    uint8 comparisonEnum,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    // Get the token address from the first offer item
    address token = zoneParameters.offer[0].token;

    // Get the id from the first offer item
    uint256 id = zoneParameters.offer[0].identifier;
    return abi.encodePacked(uint8(0x01), abi.encode(comparisonEnum, token, id, traitValue, traitKey));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-2, which specifies
   *    the token and identifier from the first consideration item as well as a comparison enum, trait key and expected trait value
   * @param zoneParameters the zoneParameters of the order whose first consideration will be used for the token and identifier
   * @param comparisonEnum The comparison enum 0 - 5
   * @param traitValue The expecta value of the trait
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @return bytes the encoded extra data with added substandard
   */
  function encodeSubstandard2(
    ZoneParameters memory zoneParameters,
    uint8 comparisonEnum,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    // Get the token address from the first consideration item
    address token = zoneParameters.consideration[0].token;

    // Get the id from the first consideration item
    uint256 identifier = zoneParameters.consideration[0].identifier;
    return abi.encodePacked(uint8(0x02), abi.encode(comparisonEnum, token, identifier, traitValue, traitKey));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-3,
   * which specifies a single comparison enum, token, identifier, traitValue and traitKey
   * @param comparisonEnum the comparison enum 0 - 5
   * @param token the address of the collection
   * @param identifier the tokenId of the token to be checked
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @param traitValue the expected value of the trait.
   * @return bytes the encoded extra data with added substandard
   */
  function encodeSubstandard3(
    uint8 comparisonEnum,
    address token,
    uint256 identifier,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(0x03), abi.encode(comparisonEnum, token, identifier, traitValue, traitKey));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-4, which specifies a single comparison
   * enum and token and multiple identifiers,  single trait key and trait value.
   * each comparison is against a single identifier and a single traitValue with a single tratKey.
   * @param comparisonEnum the comparison enum 0 - 5
   * @param token the address of the collection
   * @param identifiers the tokenId of the token to be checked
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @param traitValue the expected value of the trait.
   * @return bytes the encoded extra data with added substandard
   */
  function encodeSubstandard4(
    uint8 comparisonEnum,
    address token,
    uint256[] memory identifiers,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(0x04), abi.encode(comparisonEnum, token, identifiers, traitValue, traitKey));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-5, which specifies a single tokenIdentifier
   * @param comparisonStruct the struct of comparison data with the following values:
   *        - uint8[] comparisonEnums the array of comparison enums for each trait key and expected value, must be the same length as the trait keys and values.
   *        - address token the address of the token whose traits will be checked
   *        - address traits the address that contains the ERC7496 traits.  this is useful if you have an erc712 with traits availible at a
   *          different address leave as address(0) if the traits can be retreived from the same address as the token
   *        - uint256 identifier the identifier of the token to be checked;
   *        - bytes32[] traitValues the array of expected trait values
   *        - bytes32[] traitKeys the encoded trait keys ;
   * @return bytes the encoded extra data with added substandard
   */
  function encodeSubstandard5(Substandard5Comparison memory comparisonStruct) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(0x05), abi.encode(comparisonStruct));
  }
}
