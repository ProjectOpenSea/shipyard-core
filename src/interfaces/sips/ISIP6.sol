// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISIP5} from "./ISIP5.sol";

// https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-6.md

interface ISIP6 is ISIP5 {
    /// @dev Revert with an error if the version supplied in extraData or context is not supported.
    error UnsupportedExtraDataVersion(uint8 version);
    /// @dev Revert with an error if the extraData or context is not encoded properly.
    error InvalidExtraDataEncoding(uint8 version);
}
