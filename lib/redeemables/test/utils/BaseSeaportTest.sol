// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {DifferentialTest} from "./DifferentialTest.sol";
import {ConduitControllerInterface} from "seaport-sol/src/ConduitControllerInterface.sol";
import {ConduitController} from "seaport-core/src/conduit/ConduitController.sol";
import {ConsiderationInterface} from "seaport-types/src/interfaces/ConsiderationInterface.sol";
import {Consideration} from "seaport-core/src/lib/Consideration.sol";
import {Conduit} from "seaport-core/src/conduit/Conduit.sol";

/// @dev Base test case that deploys Consideration and its dependencies.
contract BaseSeaportTest is DifferentialTest {
    using stdStorage for StdStorage;

    bool coverage_or_debug;
    bytes32 conduitKey;

    Conduit conduit;
    Conduit referenceConduit;
    ConduitControllerInterface conduitController;
    ConsiderationInterface seaport;

    function stringEq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function debugEnabled() internal returns (bool) {
        return vm.envOr("SEAPORT_COVERAGE", false) || debugProfileEnabled();
    }

    function debugProfileEnabled() internal returns (bool) {
        string memory env = vm.envOr("FOUNDRY_PROFILE", string(""));
        return stringEq(env, "debug") || stringEq(env, "moat_debug");
    }

    function setUp() public virtual {
        // Conditionally deploy contracts normally or from precompiled source
        // deploys normally when SEAPORT_COVERAGE is true for coverage analysis
        // or when FOUNDRY_PROFILE is "debug" for debugging with source maps
        // deploys from precompiled source when both are false.
        coverage_or_debug = debugEnabled();

        conduitKey = bytes32(uint256(uint160(address(this))) << 96);
        _deployAndConfigurePrecompiledOptimizedConsideration();

        vm.label(address(conduitController), "conduitController");
        vm.label(address(seaport), "seaport");
        vm.label(address(conduit), "conduit");
        vm.label(address(this), "testContract");
    }

    /**
     * @dev Get the configured preferred Seaport
     */
    function getSeaport() internal view returns (ConsiderationInterface seaport_) {
        seaport_ = seaport;
    }

    /**
     * @dev Get the configured preferred ConduitController
     */
    function getConduitController() internal view returns (ConduitControllerInterface conduitController_) {
        conduitController_ = conduitController;
    }

    ///@dev deploy optimized consideration contracts from pre-compiled source
    //      (solc-0.8.19, IR pipeline enabled, unless running coverage or debug)
    function _deployAndConfigurePrecompiledOptimizedConsideration() public {
        conduitController = new ConduitController();
        seaport = new Consideration(address(conduitController));

        //create conduit, update channel
        conduit = Conduit(conduitController.createConduit(conduitKey, address(this)));
        conduitController.updateChannel(address(conduit), address(seaport), true);
    }

    function signOrder(ConsiderationInterface _consideration, uint256 _pkOfSigner, bytes32 _orderHash)
        internal
        view
        returns (bytes memory)
    {
        (bytes32 r, bytes32 s, uint8 v) = getSignatureComponents(_consideration, _pkOfSigner, _orderHash);
        return abi.encodePacked(r, s, v);
    }

    function getSignatureComponents(ConsiderationInterface _consideration, uint256 _pkOfSigner, bytes32 _orderHash)
        internal
        view
        returns (bytes32, bytes32, uint8)
    {
        (, bytes32 domainSeparator,) = _consideration.information();
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(_pkOfSigner, keccak256(abi.encodePacked(bytes2(0x1901), domainSeparator, _orderHash)));
        return (r, s, v);
    }
}
