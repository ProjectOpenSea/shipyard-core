// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ContractOffererInterface} from "seaport-types/interfaces/ContractOffererInterface.sol";
import {ISIP5, Schema} from "./ISIP5.sol";
import {IERC165} from "forge-std/interfaces/IERC165.sol";

interface ISIP10 is ISIP5, ContractOffererInterface {
    function documentationURI() external view returns (string memory);
    function canTransfer(uint256 tokenId) external view returns (bool);
    function getSeaportMetadata()
        external
        view
        override(ISIP5, ContractOffererInterface)
        returns (string memory name, Schema[] memory schemas);
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC165, ContractOffererInterface)
        returns (bool);
}
