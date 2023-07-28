// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import {ISIP5, Schema} from "shipyard-core/interfaces/sips/ISIP5.sol";
// import {ISIP7} from "shipyard-core/interfaces/sips/ISIP7.sol";

// abstract contract SIP7 is ISIP7 {
//     bytes32 immutable domainSeparator;
//     string apiEndpoint;
//     uint256[] substandards;
//     string constant documentationURI = "hi";

//     function sip7Information()
//         public
//         view
//         returns (
//             bytes32 _domainSeparator,
//             string memory _apiEndpoint,
//             uint256[] memory _substandards,
//             string memory _documentationURI
//         )
//     {
//         return (domainSeparator, apiEndpoint, substandards, documentationURI);
//     }

//     function getSeaportMetadata() external view returns (string memory _name, Schema[] memory schemas) {
//         bytes memory empty;
//         schemas = new Schema[](2);
//         schemas[0] = Schema(5, empty);
//         schemas[1] = Schema(7, abi.encode(domainSeparator, apiEndpoint, substandards, documentationURI));
//         return (name(), schemas);
//     }

//     function name() public pure returns (string memory) {
//         return "SIP-7";
//     }
// }
