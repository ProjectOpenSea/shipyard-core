// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Standard Interface Delegation
interface IERCInterfaceDelegation {
    /// Emitted when delegation of an interface changes.
    event InterfaceDelegated(bytes4 indexed interfaceID, address indexed previousDelegate, address indexed newDelegate);

    /// Get the address of the contract implementing the interface, or the null address if it is not delegated.
    function delegatesInterface(bytes4 interfaceID) external view returns (address);

    /// Set the address of the contract implementing the interface, or the null address if removing the delegation.
    function setInterfaceDelegate(bytes4 interfaceID, address _newDelegate) external;
}
