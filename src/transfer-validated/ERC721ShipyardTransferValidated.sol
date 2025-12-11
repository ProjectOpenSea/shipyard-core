// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "solady/src/auth/Ownable.sol";
import {ERC721} from "solady/src/tokens/ERC721.sol";
import {ERC721ConduitPreapproved_Solady} from "../tokens/erc721/ERC721ConduitPreapproved_Solady.sol";
import {TokenTransferValidator, TokenTransferValidatorStorage} from "./lib/TokenTransferValidator.sol";
import {ICreatorToken} from "../interfaces/transfer-validated/ICreatorToken.sol";
import {ITransferValidator721} from "../interfaces/transfer-validated/ITransferValidator.sol";

contract ERC721ShipyardTransferValidated is ERC721ConduitPreapproved_Solady, TokenTransferValidator, Ownable {
    using TokenTransferValidatorStorage for TokenTransferValidatorStorage.Layout;

    constructor(address initialTransferValidator) ERC721ConduitPreapproved_Solady() {
        // Set the initial contract owner.
        _initializeOwner(msg.sender);

        // Set the initial transfer validator.
        if (initialTransferValidator != address(0)) {
            _setTransferValidator(initialTransferValidator);
        }
    }

    /// @notice Returns the transfer validation function used.
    function getTransferValidationFunction() external pure returns (bytes4 functionSignature, bool isViewFunction) {
        functionSignature = ITransferValidator721.validateTransfer.selector;
        isViewFunction = false;
    }

    /// @notice Set the transfer validator. Only callable by the token owner.
    function setTransferValidator(address newValidator) external onlyOwner {
        // Set the new transfer validator.
        _setTransferValidator(newValidator);
    }

    /// @dev Hook that is called before any token transfer. This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 id) internal virtual override {
        if (from != address(0) && to != address(0)) {
            // Call the transfer validator if one is set.
            address transferValidator = TokenTransferValidatorStorage.layout()._transferValidator;
            if (transferValidator != address(0)) {
                ITransferValidator721(transferValidator).validateTransfer(msg.sender, from, to, id);
            }
        }
    }

    /// @dev Override supportsInterface to additionally return true for ICreatorToken.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || ERC721.supportsInterface(interfaceId);
    }

    /// @dev Replace me with the token name.
    function name() public view virtual override returns (string memory) {
        return "ERC721ShipyardTransferValidated";
    }

    /// @dev Replace me with the token symbol.
    function symbol() public view virtual override returns (string memory) {
        return "ERC721-S-TV";
    }

    /// @dev Replace me with the token URI.
    function tokenURI(
        uint256 /* id */
    )
        public
        view
        virtual
        override
        returns (string memory)
    {
        return "";
    }
}
