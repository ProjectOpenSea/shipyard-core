// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {ERC20} from "solady/src/tokens/ERC20.sol";

// Used for minting test ERC20s in our tests
contract TestERC20 is ERC20 {
    bool public blocked;

    bool public noReturnData;

    constructor() {
        blocked = false;
        noReturnData = false;
    }

    function blockTransfer(bool blocking) external {
        blocked = blocking;
    }

    function setNoReturnData(bool noReturn) external {
        noReturnData = noReturn;
    }

    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool ok) {
        if (blocked) {
            return false;
        }

        uint256 allowed = allowance(from, msg.sender);

        if (amount > allowed) {
            revert("NOT_AUTHORIZED");
        }

        super.transferFrom(from, to, amount);

        if (noReturnData) {
            assembly {
                return(0, 0)
            }
        }

        ok = true;
    }

    function name() public view virtual override returns (string memory) {
        return "TestERC20";
    }

    function symbol() public view virtual override returns (string memory) {
        return "TST20";
    }
}
