// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20ConduitPreapproved_OZ, ERC20} from "../../../tokens/erc20/ERC20ConduitPreapproved_OZ.sol";

contract ERC20_OZ is ERC20ConduitPreapproved_OZ {
    constructor() ERC20("ERC20_OZ", "ERC20_OZ") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
