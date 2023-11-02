// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {Schema} from "seaport-types/src/lib/ConsiderationStructs.sol";
/**
 * @title SIP-5: Contract Metadata Interface for Seaport Contracts
 */

interface ISIP5 is IERC165 {
    /**
     * @dev An event that is emitted when a SIP-5 compatible contract is deployed.
     */
    event SeaportCompatibleContractDeployed();

    /**
     * @dev Returns Seaport metadata for this contract, returning the
     *      contract name and supported schemas.
     *
     * @return name    The contract name
     * @return schemas The supported SIPs
     */
    function getSeaportMetadata() external view returns (string memory name, Schema[] memory schemas);
}
