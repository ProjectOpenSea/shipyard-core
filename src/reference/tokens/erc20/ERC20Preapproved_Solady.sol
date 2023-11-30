// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20ConduitPreapproved_Solady, ERC20} from "../../../tokens/erc20/ERC20ConduitPreapproved_Solady.sol";

contract ERC20_Solady is ERC20ConduitPreapproved_Solady {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    /// @dev Exposed to test internal function
    function spendAllowance(address owner, address spender, uint256 amount) public {
        _spendAllowance(owner, spender, amount);
    }

    /// @dev Exposed to test internal function
    function approve(address owner, address spender, uint256 amount) public {
        _approve(owner, spender, amount);
    }

    function name() public pure override returns (string memory) {
        return "Test";
    }

    function symbol() public pure override returns (string memory) {
        return "TST";
    }
}
