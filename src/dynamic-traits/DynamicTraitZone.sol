// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ZoneInterface} from "seaport-types/interfaces/ZoneInterface.sol";
import {Schema, ZoneParameters} from "seaport-types/lib/ConsiderationStructs.sol";
import {SIP5} from "../reference/sips/SIP5.sol";
import {IERC165} from "forge-std/interfaces/IERC165.sol";

contract DynamicTraitZone is ZoneInterface, SIP5 {
    error InvalidDynamicTraitValue(
        address token, bytes32 traitKey, bytes32 expectedTraitValue, bytes32 actualTraitValue
    );

    function validateOrder(ZoneParameters calldata zoneParameters) external view virtual override returns (bytes4) {}

    function name() public view virtual override returns (string memory) {
        return "DynamicTraitZone";
    }

    function getSeaportMetadata()
        external
        view
        virtual
        override(ZoneInterface, SIP5)
        returns (string memory _name, Schema[] memory schemas)
    {
        schemas = new Schema[](1);
        schemas[0] = _sip5Schema();
        return (name(), schemas);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ZoneInterface, IERC165)
        returns (bool)
    {
        return interfaceId == type(ZoneInterface).interfaceId || interfaceId == type(SIP5).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }
}
