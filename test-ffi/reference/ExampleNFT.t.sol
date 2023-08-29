// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Base64} from "solady/utils/Base64.sol";
import {Test} from "forge-std/Test.sol";
import {ExampleNFT} from "src/reference/ExampleNFT.sol";

struct Attribute {
    string attrType;
    string value;
    string displayType;
}

contract ExampleNFTTest is Test {
    ExampleNFT testExampleNft;

    string TEMP_JSON_PATH = "./test-ffi/tmp/temp.json";
    string PROCESS_JSON_PATH = "./test-ffi/scripts/process_json.js";

    function setUp() public {
        testExampleNft = new ExampleNFT();
    }

    function testStringURI(uint256 tokenId) public {
        _populateTempFileWithJson(tokenId);

        (string memory name, string memory description, string memory image) = _getNameDescriptionAndImage();

        assertEq(name, _generateExpectedTokenName(tokenId), "The token name should be Example NFT #<tokenId>");
        assertEq(description, "This is an example NFT", "The description should be This is an example NFT");
        assertEq(image, _generateExpectedTokenImage(tokenId), "The image is incorrect.");

        // Manually or programmatically set up the expected attributes here.
        Attribute[] memory attributes = new Attribute[](3);

        attributes[0] = Attribute({attrType: "Example Attribute", value: "Example Value", displayType: "noDisplayType"});
        attributes[1] = Attribute({attrType: "Number", value: vm.toString(tokenId), displayType: "number"});
        attributes[2] =
            Attribute({attrType: "Parity", value: tokenId % 2 == 0 ? "Even" : "Odd", displayType: "noDisplayType"});

        for (uint256 i; i < 3; i++) {
            (string memory attrType, string memory value, string memory displayType) = _getAttributeAtIndex(i);

            assertEq(
                attrType, attributes[i].attrType, _generateError(tokenId, i, "attrType inconsistent with expected")
            );
            assertEq(value, attributes[i].value, _generateError(tokenId, i, "value inconsistent with expected"));
            assertEq(
                displayType,
                attributes[i].displayType,
                _generateError(tokenId, i, "displayType inconsistent with expected")
            );
        }
    }

    function _populateTempFileWithJson(uint256 tokenId) internal {
        // Get the raw URI response.
        string memory rawUri = testExampleNft.tokenURI(tokenId);
        // Remove the data:application/json;base64, prefix.
        string memory uri = _cleanedUri(rawUri);
        // Decode the base64 encoded json.
        bytes memory decoded = Base64.decode(uri);

        // Write the decoded json to a file.
        vm.writeFile(TEMP_JSON_PATH, string(decoded));
    }

    function _cleanedUri(string memory uri) internal pure returns (string memory) {
        uint256 stringLength;

        // Get the length of the string from the abi encoded version.
        assembly {
            stringLength := mload(uri)
        }

        // Remove the data:application/json;base64, prefix.
        return _substring(uri, 29, stringLength);
    }

    function _substring(string memory str, uint256 startIndex, uint256 endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);

        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _getNameDescriptionAndImage()
        internal
        returns (string memory name, string memory description, string memory image)
    {
        // Run the process_json.js script on the file to extract the values.
        // This will also check for json validity.
        string[] memory commandLineInputs = new string[](4);
        commandLineInputs[0] = "node";
        commandLineInputs[1] = PROCESS_JSON_PATH;
        // In ffi, the script is executed from the top-level directory, so
        // there has to be a way to specify the path to the file where the
        // json is written.
        commandLineInputs[2] = TEMP_JSON_PATH;
        // Optional field. Default is to only get the top level values (name,
        // description, and image). This is present for the sake of
        // explicitness.
        commandLineInputs[3] = "--top-level";

        (name, description, image) = abi.decode(vm.ffi(commandLineInputs), (string, string, string));
    }

    function _getAttributeAtIndex(uint256 attributeIndex)
        internal
        returns (string memory attrType, string memory value, string memory displayType)
    {
        // Run the process_json.js script on the file to extract the values.
        // This will also check for json validity.
        string[] memory commandLineInputs = new string[](5);
        commandLineInputs[0] = "node";
        commandLineInputs[1] = PROCESS_JSON_PATH;
        // In ffi, the script is executed from the top-level directory, so
        // there has to be a way to specify the path to the file where the
        // json is written.
        commandLineInputs[2] = TEMP_JSON_PATH;
        // Optional. Default is to only get the top level values (name,
        // description, and image). This is present for the sake of
        // explicitness.
        commandLineInputs[3] = "--attribute";
        commandLineInputs[4] = vm.toString(attributeIndex);

        (attrType, value, displayType) = abi.decode(vm.ffi(commandLineInputs), (string, string, string));
    }

    function _generateExpectedTokenName(uint256 tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked("Example NFT #", vm.toString(uint256(tokenId))));
    }

    function _generateExpectedTokenImage(uint256 tokenId) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                'data:image/svg+xml;<svg xmlns=\\"http://www.w3.org/2000/svg\\" width=\\"500\\" height=\\"500\\" ><rect width=\\"500\\" height=\\"500\\" fill=\\"lightgray\\" /><text x=\\"50%\\" y=\\"50%\\" dominant-baseline=\\"middle\\" text-anchor=\\"middle\\" font-size=\\"48\\" fill=\\"black\\" >',
                vm.toString(tokenId),
                "</text></svg>"
            )
        );
    }

    function _generateError(uint256 tokenId, uint256 traitIndex, string memory message)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "Error: ", message, " for token ", vm.toString(tokenId), " and trait index ", vm.toString(traitIndex)
            )
        );
    }
}
