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
    function generateZoneHash(bytes[] memory fixedData) internal pure returns (bytes32 compositeHash) {
        ///@solidity memory-safe-assembly
        assembly {
            // get free memory pointer
            let freePtr := mload(0x40)
            // start intermediate hashes at freePtr
            let writeOffset := freePtr
            // calculate length of array in bytes
            let fixedDataArrayBytesLength := shl(5, mload(fixedData))
            // get offset of first fixedData pointer
            let fixedDataOffset := add(fixedData, 0x20)
            // calculate first word after the end of the array
            let fixedDataEnd := add(fixedDataOffset, fixedDataArrayBytesLength)
            for {
                // start reading at the first fixedData pointer
                let readOffset := fixedDataOffset
            } lt(readOffset, fixedDataEnd) {
                // increment readOffset by one word after each loop
                readOffset := add(0x20, readOffset)
                // increment writeOffset by one word after each loop
                writeOffset := add(0x20, writeOffset)
            } {
                // load the pointer to the fixedData bytes array
                let bytesPointer := mload(readOffset)
                // load the length of the fixedData array
                let bytesLen := mload(bytesPointer)
                // calculate the start of the fixedData array
                let bytesOffset := add(bytesPointer, 0x20)
                // store the "intermediate" keccak256 hash of the (packed) fixedData array at writeOffset
                mstore(writeOffset, keccak256(bytesOffset, bytesLen))
            }
            // hash the consecutive intermediate hashes
            compositeHash := keccak256(freePtr, fixedDataArrayBytesLength)
        }
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 0, which takes
     *         a single variable data field. Encodes a 0-byte for substandard version to save
     *         on calldata gas overhead.
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard1Efficient(bytes memory variableData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x00), variableData);
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 0, which takes
     *         a single variable data field.
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard1(bytes memory variableData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x01), variableData);
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 1, which takes
     *         a single fixed data field.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     */
    function encodeSubstandard2(bytes memory fixedData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x02), fixedData);
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 2, which takes
     *         a single fixed data field and a single variable data field.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard3(bytes memory fixedData, bytes memory variableData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(uint8(0x03), abi.encode(fixedData, variableData));
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 3, which takes
     *         an array of variable data fields.
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard4(bytes[] memory variableData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x04), abi.encode(variableData));
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 4, which takes
     *         an array of fixed data fields.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     */
    function encodeSubstandard5(bytes[] memory fixedData) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x05), abi.encode(fixedData));
    }

    /**
     * @notice Encode extraData for an SIP6 contract that implements substandard 5, which takes
     *         an array of fixed data fields and an array of variable data fields.
     * @param fixedData The fixed data to be encoded for a SIP6 contract
     * @param variableData The variable data to be encoded for a SIP6 contract
     */
    function encodeSubstandard6(bytes[] memory fixedData, bytes[] memory variableData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(uint8(0x06), abi.encode(fixedData, variableData));
    }
}
