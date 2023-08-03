// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISIP10, IERC165} from "shipyard-core/interfaces/sips/ISIP10.sol";
import {SIP5, Schema} from "shipyard-core/reference/sips/SIP5.sol";
import {IERC165} from "forge-std/interfaces/IERC165.sol";

abstract contract SIP10 is ISIP10, SIP5 {
    function getSeaportMetadata()
        external
        view
        virtual
        override(ISIP10, SIP5)
        returns (string memory _name, Schema[] memory schemas)
    {
        schemas = new Schema[](2);
        schemas[0] = _sip5Schema();
        schemas[0] = _sip10Schema();
        return (name(), schemas);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ISIP10, IERC165) returns (bool);

    function _sip10Schema() internal view returns (Schema memory) {
        return Schema(10, abi.encode(_sip10Substandards(), _documentationURI()));
    }

    function _sip10Substandards() internal view virtual returns (uint256[] memory);
    function _documentationURI() internal view virtual returns (string memory);
}
