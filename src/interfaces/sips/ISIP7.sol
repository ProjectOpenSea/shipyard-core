// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISIP5} from "../../interfaces/sips/ISIP5.sol";

interface ISIP7 is ISIP5 {
    /**
     * @notice Returns the relevant information for SIP-7, including the domain
     *         separator, signature request API endpoint, supports SIP6-
     *         substandards, and documentation URI.
     * @return domainSeparator The domain separator for this contract
     * @return apiEndpoint The API endpoint for signature requests
     * @return substandards The substandards supported by this contract
     * @return documentationURI The documentation URI for this contract
     */
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
