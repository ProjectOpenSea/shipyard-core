// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISIP5} from "./ISIP5.sol";

interface ISIP7 is ISIP5 {
    function sip7Information()
        external
        view
        returns (
            bytes32 domainSeparator,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        );
}
