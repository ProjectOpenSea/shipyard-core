// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library StringTestUtility {
    function countChar(string memory str, bytes1 c) internal pure returns (uint256) {
        uint256 count;
        bytes memory strBytes = bytes(str);
        for (uint256 i = 0; i < strBytes.length; ++i) {
            if (strBytes[i] == c) {
                ++count;
            }
        }
        return count;
    }
}
