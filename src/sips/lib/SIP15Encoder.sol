// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum Comparator {
    EQUAL_TO,
    LESS_THAN,
    LESS_THAN_OR_EQUAL_TO,
    GREATER_THAN,
    GREATER_THAN_OR_EQUAL_TO
}

struct DynamicTraitRestraint {
    Comparator comparator;
    address token;
    bytes32 traitKey;
    bytes32 expectedTraitValue;
}

library SIP15Encoder {
    function encodeSIP15Substandard1_Efficient(
        Comparator comparator,
        address token,
        bytes32 traitKey,
        bytes32 expectedTraitValue
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(0), comparator, token, traitKey, expectedTraitValue);
    }

    function encodeSIP15Substandard1(Comparator comparator, address token, bytes32 traitKey, bytes32 expectedTraitValue)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(uint8(1), comparator, token, traitKey, expectedTraitValue);
    }

    function encodeSIP15Substandard2(DynamicTraitRestraint[] memory dynamicTraitRestraints)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(uint8(2), dynamicTraitRestraints);
    }

    function encodeSIP15Substandard3(address token, uint256 traitKeysLength, bytes32 expectedHash)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(uint8(3), token, traitKeysLength, expectedHash);
    }
}
