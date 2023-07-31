// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SIP6Encoder {
    /**
     * @notice Generate a zone hash for an SIP6 contract that implements substandards 1 and/or 2, which
     *         derives its zoneHash from one fixed data field.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     */
    function generateZoneHash(bytes memory fixedData) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(fixedData));
    }

    /**
     * @notice Generate a zone hash for an SIP6 contract that implements substandards 4 and/or 5,
     *         which derives its zoneHash from an array of fixed data fields.
     * @param fixedData Array of fixed data bytes to be encoded for a SIP6 contract
     */
    function generateZoneHash(bytes[] memory fixedData) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](fixedData.length);
        uint256 fixedDataLength = fixedData.length;
        for (uint256 i = 0; i < fixedDataLength;) {
            hashes[i] = keccak256(fixedData[i]);
            unchecked {
                ++i;
            }
        }
        bytes32 compositeHash;
        ///@solidity memory-safe-assembly
        assembly {
            compositeHash := keccak256(add(hashes, 0x20), shl(5, mload(hashes)))
        }
        return compositeHash;
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 0, which takes
     *         a single variable data field.
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard0(bytes memory variableData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x00), variableData);
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 1, which takes
     *         a single fixed data field.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     */
    function encodeSubstandard1(bytes memory fixedData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x01), fixedData);
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 2, which takes
     *         a single fixed data field and a single variable data field.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard2(bytes memory fixedData, bytes memory variableData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(uint8(0x02), abi.encode(fixedData, variableData));
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 3, which takes
     *         an array of variable data fields.
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard3(bytes[] memory variableData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x03), abi.encode(variableData));
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 4, which takes
     *         an array of fixed data fields.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     */
    function encodeSubstandard4(bytes[] memory fixedData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x04), abi.encode(fixedData));
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 5, which takes
     *         an array of fixed data fields and an array of variable data fields.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard5(bytes[] memory fixedData, bytes[] memory variableData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(uint8(0x05), abi.encode(fixedData, variableData));
    }
}
