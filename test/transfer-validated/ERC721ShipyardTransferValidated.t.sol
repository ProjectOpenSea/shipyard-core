// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {TestPlus} from "solady/test/utils/TestPlus.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {ICreatorToken} from "src/interfaces/transfer-validated/ICreatorToken.sol";
import {ITransferValidator721} from "src/interfaces/transfer-validated/ITransferValidator.sol";
import {MockTransferValidator} from "./mock/MockTransferValidator.sol";
import {ERC721ShipyardTransferValidated} from "src/transfer-validated/ERC721ShipyardTransferValidated.sol";

contract ERC721ShipyardTransferValidatedWithMint is ERC721ShipyardTransferValidated {
    constructor(address initialTransferValidator) ERC721ShipyardTransferValidated(initialTransferValidator) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract TestERC721ShipyardTransferValidated is Test, TestPlus {
    MockTransferValidator transferValidatorAlwaysSucceeds = new MockTransferValidator(false);
    MockTransferValidator transferValidatorAlwaysReverts = new MockTransferValidator(true);

    event TransferValidatorUpdated(address oldValidator, address newValidator);

    ERC721ShipyardTransferValidatedWithMint token;

    function setUp() public {
        token = new ERC721ShipyardTransferValidatedWithMint(address(0));
    }

    function testOnlyOwnerCanSetTransferValidator() public {
        assertEq(token.getTransferValidator(), address(0));

        vm.prank(address(token));
        vm.expectRevert(Ownable.Unauthorized.selector);
        token.setTransferValidator(address(transferValidatorAlwaysSucceeds));

        token.setTransferValidator(address(transferValidatorAlwaysSucceeds));
        assertEq(token.getTransferValidator(), address(transferValidatorAlwaysSucceeds));
    }

    function testTransferValidatedSetInConstructor() public {
        ERC721ShipyardTransferValidatedWithMint token2 =
            new ERC721ShipyardTransferValidatedWithMint(address(transferValidatorAlwaysSucceeds));

        assertEq(token2.getTransferValidator(), address(transferValidatorAlwaysSucceeds));
    }

    function testTransferValidatorIsCalledOnTransfer() public {
        token.mint(address(this), 1);
        token.mint(address(this), 2);

        vm.expectEmit(true, true, true, true);
        emit TransferValidatorUpdated(address(0), address(transferValidatorAlwaysSucceeds));
        token.setTransferValidator(address(transferValidatorAlwaysSucceeds));
        token.safeTransferFrom(address(this), msg.sender, 1);

        vm.expectEmit(true, true, true, true);
        emit TransferValidatorUpdated(address(transferValidatorAlwaysSucceeds), address(transferValidatorAlwaysReverts));
        token.setTransferValidator(address(transferValidatorAlwaysReverts));
        vm.expectRevert("MockTransferValidator: always reverts");
        token.safeTransferFrom(address(this), msg.sender, 2);

        // When set to null address, transfer should succeed without calling the validator
        vm.expectEmit(true, true, true, true);
        emit TransferValidatorUpdated(address(transferValidatorAlwaysReverts), address(0));
        token.setTransferValidator(address(0));
        token.safeTransferFrom(address(this), msg.sender, 2);
    }

    function testGetTransferValidationFunction() public {
        (bytes4 functionSignature, bool isViewFunction) = token.getTransferValidationFunction();
        assertEq(functionSignature, ITransferValidator721.validateTransfer.selector);
        assertEq(isViewFunction, false);
    }

    function testSupportsInterface() public {
        assertEq(token.supportsInterface(type(ICreatorToken).interfaceId), true);
    }
}
