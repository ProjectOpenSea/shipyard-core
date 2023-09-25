// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Schema} from "../../interfaces/sips/ISIP5.sol";
import {ISIP5} from "../../interfaces/sips/ISIP5.sol";

abstract contract SIP5 is ISIP5 {
    constructor() {
        emit SeaportCompatibleContractDeployed();
    }

    function getSeaportMetadata() external view virtual returns (string memory _name, Schema[] memory schemas) {
        schemas = new Schema[](1);
        schemas[0] = _sip5Schema();
        return (name(), schemas);
    }

    function _sip5Schema() internal pure returns (Schema memory) {
        bytes memory empty;
        return Schema(5, empty);
    }

    function name() public view virtual returns (string memory);
}
