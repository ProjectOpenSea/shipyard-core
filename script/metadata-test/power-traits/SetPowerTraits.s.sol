// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTPowerTraits} from "script/metadata-test/power-traits/TestNFTPowerTraits.sol";

/**
 * @title SetPowerTraits
 * @notice Helper script to set/update power level traits on an existing TestNFTPowerTraits deployment.
 *
 * Usage:
 *   # Set power level for a single NFT (raw units)
 *   forge script script/metadata-test/power-traits/SetPowerTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK> \
 *     --sig "setPower(address,uint256,uint256)" <CONTRACT> <TOKEN_ID> <POWER_UNITS>
 *
 *   # Set power level using whole units (will multiply by 1e18)
 *   forge script script/metadata-test/power-traits/SetPowerTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK> \
 *     --sig "setPowerWhole(address,uint256,uint256)" <CONTRACT> <TOKEN_ID> <POWER>
 *
 *   # Batch set power levels for multiple NFTs
 *   forge script script/metadata-test/power-traits/SetPowerTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK> \
 *     --sig "batchSetPower(address,uint256[],uint256[])" <CONTRACT> "[1,2,3]" "[1e18,2e18,3e18]"
 */
contract SetPowerTraits is Script {
    bytes32 constant POWER_KEY = keccak256("power");
    uint256 constant ONE_UNIT = 1e18;

    /// @notice Set power level for a single NFT (value in raw units)
    function setPower(address contractAddr, uint256 tokenId, uint256 powerUnits) public {
        vm.startBroadcast();

        TestNFTPowerTraits nft = TestNFTPowerTraits(contractAddr);

        // Use setTraitIfChanged to avoid revert if unchanged
        nft.setTraitIfChanged(tokenId, POWER_KEY, bytes32(powerUnits));

        console2.log("Set power level for NFT", tokenId);
        console2.log("Power (units):", powerUnits);
        console2.log("Power (whole):", powerUnits / ONE_UNIT);

        vm.stopBroadcast();
    }

    /// @notice Set power level for a single NFT (value in whole power, will multiply by 1e18)
    function setPowerWhole(address contractAddr, uint256 tokenId, uint256 power) public {
        setPower(contractAddr, tokenId, power * ONE_UNIT);
    }

    /// @notice Set power level with fractional value (whole + fraction in units)
    /// @param wholePower Number of whole power
    /// @param fractionUnits Fractional part in units (0 to 999999999999999999)
    function setPowerMixed(address contractAddr, uint256 tokenId, uint256 wholePower, uint256 fractionUnits) public {
        require(fractionUnits < ONE_UNIT, "Fraction must be less than 1e18");
        uint256 totalUnits = wholePower * ONE_UNIT + fractionUnits;
        setPower(contractAddr, tokenId, totalUnits);
    }

    /// @notice Batch set power levels for multiple NFTs
    function batchSetPower(address contractAddr, uint256[] calldata tokenIds, uint256[] calldata powerUnits) public {
        require(tokenIds.length == powerUnits.length, "Length mismatch");

        vm.startBroadcast();

        TestNFTPowerTraits nft = TestNFTPowerTraits(contractAddr);

        bytes32[] memory values = new bytes32[](powerUnits.length);
        for (uint256 i = 0; i < powerUnits.length; i++) {
            values[i] = bytes32(powerUnits[i]);
        }

        nft.batchSetTrait(tokenIds, POWER_KEY, values);

        console2.log("Batch set power levels for", tokenIds.length, "NFTs");

        vm.stopBroadcast();
    }

    /// @notice Read and display current power level for an NFT
    function getPower(address contractAddr, uint256 tokenId) public view {
        TestNFTPowerTraits nft = TestNFTPowerTraits(contractAddr);
        uint256 powerUnits = uint256(nft.getTraitValue(tokenId, POWER_KEY));

        console2.log("NFT ID:", tokenId);
        console2.log("Power (units):", powerUnits);
        console2.log("Power (whole):", powerUnits / ONE_UNIT);
        console2.log("Fractional (units):", powerUnits % ONE_UNIT);
    }
}
