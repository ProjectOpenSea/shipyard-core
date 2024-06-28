// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseSIPDecoder} from 'shipyard-core/src/sips/lib/BaseSIPDecoder.sol';
import {Substandard5Comparison} from './SIP15Encoder.sol';

library SIP15Decoder {
  /**
   * @notice Read the SIP15 substandard version byte from the extraData field of a SIP15 encoded bytes array.
   * @param extraData bytes calldata
   * @return substandard the single byte substandard number 0-5
   */
  function decodeSubstandardVersion(bytes calldata extraData) internal pure returns (bytes1 substandard) {
    return BaseSIPDecoder.decodeSubstandardVersion(extraData);
  }
  /**
   * @notice decodes data encoding with substandard1Efficient encoder
   * @param extraData the encoded bytes with substandard and the extra data
   * @return (uint8 comparisonEnum, address token, uint256 identifier, bytes32 traitValue, bytes32 traitKey)
   */

  function decodeSubstandard1Efficient(bytes calldata extraData)
    internal
    pure
    returns (uint8, address, uint256, bytes32, bytes32)
  {
    return _decodeSingleTraitsWithOffset(extraData, 1);
  }

  /**
   * @notice decodes data encoding with substandard1 encoder
   * @param extraData the encoded bytes with substandard and the extra data
   * @return (uint8 comparisonEnum, address token, uint256 identifier, bytes32 traitValue, bytes32 traitKey)
   */
  function decodeSubstandard1(bytes calldata extraData)
    internal
    pure
    returns (uint8, address, uint256, bytes32, bytes32)
  {
    return _decodeSingleTraitsWithOffset(extraData, 1);
  }

  /**
   * @notice decodes data encoding with substandard2 encoder
   * @param extraData the encoded bytes with substandard and the extra data
   * @return (uint8 comparisonEnum, address token, uint256 identifier, bytes32 traitValue, bytes32 traitKey)
   */
  function decodeSubstandard2(bytes calldata extraData)
    internal
    pure
    returns (uint8, address, uint256, bytes32, bytes32)
  {
    return _decodeSingleTraitsWithOffset(extraData, 1);
  }

  /**
   * @notice decodes data encoding with substandard3 encoder
   * @param extraData the encoded bytes with substandard and the extra data
   * @return (uint8 comparisonEnum, address token, uint256 identifier, bytes32 traitValue, bytes32 traitKey)
   */
  function decodeSubstandard3(bytes calldata extraData)
    internal
    pure
    returns (uint8, address, uint256, bytes32, bytes32)
  {
    return _decodeSingleTraitsWithOffset(extraData, 1);
  }

  /**
   * @notice decodes data encoding with substandard4 encoder
   * @param extraData the encoded bytes with substandard and the extra data
   * @return (uint8 comparisonEnum, address token, uint256[] identifiers, bytes32 traitValue, bytes32 traitKey)
   */
  function decodeSubstandard4(bytes calldata extraData)
    internal
    pure
    returns (uint8, address, uint256[] memory, bytes32, bytes32)
  {
    return abi.decode(extraData[1:], (uint8, address, uint256[], bytes32, bytes32));
  }

  /**
   * @notice decodes data encoding with substandard1 encoder
   * @param extraData the encoded bytes with substandard and the extra data
   * @return Substandard5Comparison
   */
  function decodeSubstandard5(bytes calldata extraData) internal pure returns (Substandard5Comparison memory) {
    return abi.decode(extraData[1:], (Substandard5Comparison));
  }

  function _decodeSingleTraitsWithOffset(
    bytes calldata extraData,
    uint256 sip15DataStartRelativeOffset
  )
    internal
    pure
    returns (uint8 comparisonEnum, address token, uint256 identifier, bytes32 traitValue, bytes32 traitKey)
  {
    return abi.decode(extraData[sip15DataStartRelativeOffset:], (uint8, address, uint256, bytes32, bytes32));
  }
}
