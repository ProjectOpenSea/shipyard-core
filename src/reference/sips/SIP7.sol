// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SIP5, Schema, ISIP5} from "shipyard-core/reference/sips/SIP5.sol";
import {ISIP7} from "shipyard-core/interfaces/sips/ISIP7.sol";

abstract contract SIP7 is SIP5, ISIP7 {
    bytes32 immutable domainSeparator;

    constructor() {
        domainSeparator = _deriveDomainSeparator();
    }

    /**
     * @inheritdoc ISIP7
     */
    function sip7Information()
        external
        view
        virtual
        returns (
            bytes32 domainSeparator_,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        )
    {
        return (_domainSeparator(), _apiEndpoint(), _substandards(), _documentationURI());
    }

    function getSeaportMetadata()
        external
        view
        virtual
        override(SIP5, ISIP5)
        returns (string memory _name, Schema[] memory schemas)
    {
        schemas = new Schema[](2);
        schemas[0] = _sip5Schema();
        schemas[1] = _sip7Schema();
        return (name(), schemas);
    }

    function _sip7Schema() internal view returns (Schema memory) {
        return Schema(7, abi.encode(_domainSeparator(), _apiEndpoint(), _substandards(), _documentationURI()));
    }

    function _deriveDomainSeparator() internal view virtual returns (bytes32);

    function _domainSeparator() internal view virtual returns (bytes32);

    function _documentationURI() internal view virtual returns (string memory);

    function _apiEndpoint() internal view virtual returns (string memory);
    function _substandards() internal view virtual returns (uint256[] memory);
}
