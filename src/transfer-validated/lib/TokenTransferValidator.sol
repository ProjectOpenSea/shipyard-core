// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICreatorToken} from "../../interfaces/transfer-validated/ICreatorToken.sol";

library TokenTransferValidatorStorage {
    struct Layout {
        /// @dev Store the transfer validator. The null address means no transfer validator is set.
        address _transferValidator;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("contracts.storage.tokenTransferValidator");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/**
 * @title  TokenTransferValidator
 * @notice Functionality to use a transfer validator.
 */
abstract contract TokenTransferValidator is ICreatorToken {
    using TokenTransferValidatorStorage for TokenTransferValidatorStorage.Layout;

    /// @notice Revert with an error if the transfer validator is being set to the same address.
    error SameTransferValidator();

    /// @notice Returns the currently active transfer validator.
    ///         The null address means no transfer validator is set.
    function getTransferValidator() external view returns (address) {
        return TokenTransferValidatorStorage.layout()._transferValidator;
    }

    /// @notice Set the transfer validator.
    ///         The external method that uses this must include access control.
    function _setTransferValidator(address newValidator) internal {
        address oldValidator = TokenTransferValidatorStorage.layout()._transferValidator;
        if (oldValidator == newValidator) {
            revert SameTransferValidator();
        }
        TokenTransferValidatorStorage.layout()._transferValidator = newValidator;
        emit TransferValidatorUpdated(oldValidator, newValidator);
    }
}
