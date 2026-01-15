// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {TestNFTNumericTraits} from "script/metadata-test/numeric-traits/TestNFTNumericTraits.sol";

/**
 * @title DeployNumericTraits
 * @notice Deploys TestNFTNumericTraits and bulk mints tokens for testing OpenSea Numeric Trait Offers.
 *
 * Usage:
 *   # Deploy and mint 10 tokens to deployer
 *   forge script script/metadata-test/DeployNumericTraits.s.sol --rpc-url <RPC> --broadcast --private-key <PK>
 *
 *   # Deploy and mint custom amount to custom address
 *   forge script script/metadata-test/DeployNumericTraits.s.sol \
 *     --rpc-url <RPC> --broadcast --private-key <PK> \
 *     --sig "deploy(address,uint256)" <RECIPIENT> <AMOUNT>
 *
 * Trait Ranges:
 *   - Power: 1-9 (single digit)
 *   - Speed: 10-99 (double digit)
 *   - Energy: 100-999 (triple digit)
 *   - Experience: 10000-999999 (5-6 digits)
 */
contract DeployNumericTraits is Script {
    uint256 constant DEFAULT_AMOUNT = 10;

    function run() public {
        deploy(msg.sender, DEFAULT_AMOUNT);
    }

    function deploy(address recipient, uint256 amount) public {
        vm.startBroadcast();

        // Deploy the contract
        TestNFTNumericTraits nft = new TestNFTNumericTraits();
        console2.log("Deployed TestNFTNumericTraits at:", address(nft));

        // Bulk mint tokens
        (uint256 startId, uint256 endId) = nft.bulkMint(recipient, amount);
        console2.log("Minted tokens to:", recipient);
        console2.log("Start ID:", startId);
        console2.log("End ID:", endId);

        vm.stopBroadcast();

        // Log summary
        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("Contract: TestNFTNumericTraits");
        console2.log("Address:", address(nft));
        console2.log("Tokens minted:", amount);
        console2.log("Recipient:", recipient);
        console2.log("");
        console2.log("=== Trait Ranges ===");
        console2.log("Power: 1-9 (single digit)");
        console2.log("Speed: 10-99 (double digit)");
        console2.log("Energy: 100-999 (triple digit)");
        console2.log("Experience: 10000-999999 (5-6 digits)");
        console2.log("");

        // Show sample trait distribution
        _logSampleTraits(nft);
    }

    function _logSampleTraits(TestNFTNumericTraits nft) internal pure {
        console2.log("=== Sample Trait Distribution ===");
        console2.log("Token | Power | Speed | Energy | Experience");
        console2.log("------|-------|-------|--------|------------");

        uint256[] memory samples = new uint256[](10);
        samples[0] = 1;
        samples[1] = 10;
        samples[2] = 50;
        samples[3] = 100;
        samples[4] = 250;
        samples[5] = 500;
        samples[6] = 750;
        samples[7] = 900;
        samples[8] = 999;
        samples[9] = 1000;

        for (uint256 i = 0; i < samples.length; i++) {
            uint256 tokenId = samples[i];
            console2.log(
                string.concat(
                    _padLeft(tokenId, 5),
                    " | ",
                    _padLeft(nft.getPower(tokenId), 5),
                    " | ",
                    _padLeft(nft.getSpeed(tokenId), 5),
                    " | ",
                    _padLeft(nft.getEnergy(tokenId), 6),
                    " | ",
                    _padLeft(nft.getExperience(tokenId), 10)
                )
            );
        }
    }

    function _padLeft(uint256 value, uint256 width) internal pure returns (string memory) {
        bytes memory valueBytes = bytes(_toString(value));
        if (valueBytes.length >= width) {
            return string(valueBytes);
        }
        bytes memory result = new bytes(width);
        uint256 padding = width - valueBytes.length;
        for (uint256 i = 0; i < padding; i++) {
            result[i] = " ";
        }
        for (uint256 i = 0; i < valueBytes.length; i++) {
            result[padding + i] = valueBytes[i];
        }
        return string(result);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
