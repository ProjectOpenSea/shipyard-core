// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC1155} from "solady/src/tokens/ERC1155.sol";
import {IERCDynamicTraits} from "./interfaces/IDynamicTraits.sol";
import {SignedRedeem} from "./lib/SignedRedeem.sol";

// contract ERC1155Redeemable is ERC1155, IERCDynamicTraits, SignedRedeem {}
