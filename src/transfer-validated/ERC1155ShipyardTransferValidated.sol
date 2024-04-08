// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "solady/src/auth/Ownable.sol";
import {ERC1155} from "solady/src/tokens/ERC1155.sol";
import {ERC1155ConduitPreapproved_Solady} from "../tokens/erc1155/ERC1155ConduitPreapproved_Solady.sol";
import {TokenTransferValidator, TokenTransferValidatorStorage} from "./lib/TokenTransferValidator.sol";
import {ICreatorToken} from "../interfaces/transfer-validated/ICreatorToken.sol";
import {ITransferValidator1155} from "../interfaces/transfer-validated/ITransferValidator.sol";

contract ERC1155ShipyardTransferValidated is ERC1155ConduitPreapproved_Solady, TokenTransferValidator, Ownable {
    using TokenTransferValidatorStorage for TokenTransferValidatorStorage.Layout;

    constructor(address initialTransferValidator) ERC1155ConduitPreapproved_Solady() {
        // Set the initial contract owner.
        _initializeOwner(msg.sender);

        // Set the initial transfer validator.
        if (initialTransferValidator != address(0)) {
            _setTransferValidator(initialTransferValidator);
        }
    }

    /// @notice Returns the transfer validation function used.
    function getTransferValidationFunction() external pure returns (bytes4 functionSignature, bool isViewFunction) {
        functionSignature = ITransferValidator1155.validateTransfer.selector;
        isViewFunction = true;
    }

    /// @notice Set the transfer validator. Only callable by the token owner.
    function setTransferValidator(address newValidator) external onlyOwner {
        // Set the new transfer validator.
        _setTransferValidator(newValidator);
    }

    /// @dev Override this function to return true if `_beforeTokenTransfer` is used.
    function _useBeforeTokenTransfer() internal view virtual override returns (bool) {
        return true;
    }

    /// @dev Hook that is called before any token transfer. This includes minting and burning.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory /* data */
    ) internal virtual override {
        if (from != address(0) && to != address(0)) {
            // Call the transfer validator if one is set.
            address transferValidator = TokenTransferValidatorStorage.layout()._transferValidator;
            if (transferValidator != address(0)) {
                for (uint256 i = 0; i < ids.length; i++) {
                    ITransferValidator1155(transferValidator).validateTransfer(msg.sender, from, to, ids[i], amounts[i]);
                }
            }
        }
    }

    /// @dev Override supportsInterface to additionally return true for ICreatorToken.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || ERC1155.supportsInterface(interfaceId);
    }

    /// @dev Replace me with the token name.
    function name() public view virtual returns (string memory) {
        return "ERC1155ShipyardTransferValidated";
    }

    /// @dev Replace me with the token symbol.
    function symbol() public view virtual returns (string memory) {
        return "ERC1155-S-TV";
    }

    /// @dev Replace me with the token URI.
    function uri(uint256 /* id */ ) public view virtual override returns (string memory) {
        return "";
    }
}
