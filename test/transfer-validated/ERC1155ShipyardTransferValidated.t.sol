// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {TestPlus} from "solady/test/utils/TestPlus.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {ICreatorToken} from "src/interfaces/transfer-validated/ICreatorToken.sol";
import {ITransferValidator1155} from "src/interfaces/transfer-validated/ITransferValidator.sol";
import {MockTransferValidator} from "./mock/MockTransferValidator.sol";
import {ERC1155ShipyardTransferValidated} from "src/transfer-validated/ERC1155ShipyardTransferValidated.sol";

contract ERC1155ShipyardTransferValidatedWithMint is ERC1155ShipyardTransferValidated {
    constructor(address initialTransferValidator) ERC1155ShipyardTransferValidated(initialTransferValidator) {}

    function mint(address to, uint256 id, uint256 amount) public onlyOwner {
        _mint(to, id, amount, "");
    }
}

contract TestERC1155ShipyardTransferValidated is Test, TestPlus {
    MockTransferValidator transferValidatorAlwaysSucceeds = new MockTransferValidator(false);
    MockTransferValidator transferValidatorAlwaysReverts = new MockTransferValidator(true);

    event TransferValidatorUpdated(address oldValidator, address newValidator);

    ERC1155ShipyardTransferValidatedWithMint token;

    function setUp() public {
        token = new ERC1155ShipyardTransferValidatedWithMint(address(0));
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
        ERC1155ShipyardTransferValidatedWithMint token2 =
            new ERC1155ShipyardTransferValidatedWithMint(address(transferValidatorAlwaysSucceeds));

        assertEq(token2.getTransferValidator(), address(transferValidatorAlwaysSucceeds));
    }

    function testTransferValidatorIsCalledOnTransfer() public {
        token.mint(address(this), 1, 10);
        token.mint(address(this), 2, 10);

        vm.expectEmit(true, true, true, true);
        emit TransferValidatorUpdated(address(0), address(transferValidatorAlwaysSucceeds));
        token.setTransferValidator(address(transferValidatorAlwaysSucceeds));
        token.safeTransferFrom(address(this), msg.sender, 1, 1, "");
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 2;
        amounts[1] = 2;
        token.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");

        vm.expectEmit(true, true, true, true);
        emit TransferValidatorUpdated(address(transferValidatorAlwaysSucceeds), address(transferValidatorAlwaysReverts));
        token.setTransferValidator(address(transferValidatorAlwaysReverts));
        vm.expectRevert("MockTransferValidator: always reverts");
        token.safeTransferFrom(address(this), msg.sender, 1, 1, "");
        vm.expectRevert("MockTransferValidator: always reverts");
        token.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");

        // When set to null address, transfer should succeed without calling the validator
        vm.expectEmit(true, true, true, true);
        emit TransferValidatorUpdated(address(transferValidatorAlwaysReverts), address(0));
        token.setTransferValidator(address(0));
        token.safeTransferFrom(address(this), msg.sender, 1, 1, "");
        token.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }

    function testGetTransferValidationFunction() public {
        (bytes4 functionSignature, bool isViewFunction) = token.getTransferValidationFunction();
        assertEq(functionSignature, ITransferValidator1155.validateTransfer.selector);
        assertEq(isViewFunction, true);
    }

    function testSupportsInterface() public {
        assertEq(token.supportsInterface(type(ICreatorToken).interfaceId), true);
    }

    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata /* data */
    )
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }
}
