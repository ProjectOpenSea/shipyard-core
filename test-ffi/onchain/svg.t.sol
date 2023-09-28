// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Base64} from "solady/utils/Base64.sol";
import {Test} from "forge-std/Test.sol";
import {svg} from "../../src/onchain/svg.sol";
import {ExampleNFT} from "src/reference/ExampleNFT.sol";
import {svg} from "../../src/onchain/svg.sol";

contract svgTest is Test {
    ExampleNFT testExampleNft;

    string TEMP_JSON_PATH = "./test-ffi/tmp/temp-2.json";
    string PROCESS_JSON_PATH = "./test-ffi/scripts/process_json.js";

    string TEMP_SVG_DIR_PATH_AND_PREFIX = "./test-ffi/tmp/temp-";
    string TEMP_SVG_FILE_TYPE = ".svg";
    string VALIDATE_SVG_PATH = "./test-ffi/scripts/validate_svg.js";

    function setUp() public {
        testExampleNft = new ExampleNFT('Example', 'EXNFT');
    }

    function testValidateExampleSvg(uint256 tokenId) public {
        // Populate the json file with the json from the tokenURI function.
        _populateTempFileWithJson(tokenId);

        // Get the output of the NFT's tokenURI function and grab the image from
        // it.
        string memory image = _getImage();

        // Write the svg to a file. It's necessary to create a new file for each
        // test to prevent the tests from becoming flaky as a result of timing.
        vm.writeFile(string(abi.encodePacked(TEMP_SVG_DIR_PATH_AND_PREFIX, "example", TEMP_SVG_FILE_TYPE)), image);

        _validateSvg("example");
    }

    function testTop() public {
        _validateTopLevelSvg(
            svg.top('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "top-with-props-and-children"
        );
        _validateTopLevelSvg(svg.top('width="100" height="100"', ""), "top-with-props");
        _validateTopLevelSvg(svg.top("", ""), "top-no-props");
    }

    function testSvg() public {
        _validateTopLevelSvg(
            svg.svg_(true, 'width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "svg-with-props-and-children"
        );
        _validateTopLevelSvg(svg.svg_(true, 'width="100" height="100"', ""), "svg-with-props-includeXmlns");
        _validateTopLevelSvg(svg.svg_(false, 'width="100" height="100"', ""), "svg-with-props-no-includeXmlns");
        _validateTopLevelSvg(svg.svg_(false, "", ""), "svg-no-props");
    }

    function testG() public {
        _validateSvgElement(
            svg.g('width="100" height="100"', '<circle width="100" height="100"></circle>'), "g-with-props-and-children"
        );
        _validateSvgElement(svg.g('width="100" height="100"', ""), "g-with-props");
        _validateSvgElement(svg.g("", ""), "g-no-props");
    }

    function testPath() public {
        _validateSvgElement(
            svg.path('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "path-with-props-and-children"
        );
        _validateSvgElement(svg.path('width="100" height="100"', ""), "path-with-props");
        _validateSvgElement(svg.path("", ""), "path-no-props");
    }

    function testText() public {
        _validateSvgElement(
            svg.text('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "text-with-props-and-children"
        );
        _validateSvgElement(svg.text('width="100" height="100"', ""), "text-with-props");
        _validateSvgElement(svg.text("", ""), "text-no-props");
    }

    function testLine() public {
        _validateSvgElement(
            svg.line('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "line-with-props-and-children"
        );
        _validateSvgElement(svg.line('width="100" height="100"', ""), "line-with-props");
        _validateSvgElement(svg.line("", ""), "line-no-props");
    }

    function testCircle() public {
        _validateSvgElement(
            svg.circle('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "circle-with-props-and-children"
        );
        _validateSvgElement(svg.circle('width="100" height="100"', ""), "circle-with-props");
        _validateSvgElement(svg.circle("", ""), "circle-no-props");
    }

    function testCircleNoChildren() public {
        _validateSvgElement(svg.circle('width="100" height="100"'), "circle-no-children-with-props");
        _validateSvgElement(svg.circle(""), "circle-no-children-no-props");
    }

    function testRect() public {
        _validateSvgElement(
            svg.rect('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "rect-with-props-and-children"
        );
        _validateSvgElement(svg.rect('width="100" height="100"', ""), "rect-with-props");
        _validateSvgElement(svg.rect("", ""), "rect-no-props");
    }

    function testRectNoChildren() public {
        _validateSvgElement(svg.rect('width="100" height="100"'), "rect-no-children-with-props");
        _validateSvgElement(svg.rect(""), "rect-no-children-no-props");
    }

    function testFilter() public {
        _validateSvgElement(
            svg.filter('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "filter-with-props-and-children"
        );
        _validateSvgElement(svg.filter('width="100" height="100"', ""), "filter-with-props");
        _validateSvgElement(svg.filter("", ""), "filter-no-props");
    }

    function testCdata() public {
        _validateSvgElement(svg.cdata("<svg></svg>"), "cdata");
    }

    function testRadialGradient() public {
        _validateSvgElement(
            svg.radialGradient('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "radialGradient-with-props-and-children"
        );
        _validateSvgElement(svg.radialGradient('width="100" height="100"', ""), "radialGradient-with-props");
        _validateSvgElement(svg.radialGradient("", ""), "radialGradient-no-props");
    }

    function testLinearGradient() public {
        _validateSvgElement(
            svg.linearGradient('width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "linearGradient-with-props-and-children"
        );
        _validateSvgElement(svg.linearGradient('width="100" height="100"', ""), "linearGradient-with-props");
        _validateSvgElement(svg.linearGradient("", ""), "linearGradient-no-props");
    }

    function testGradientStop() public {
        _validateSvgElement(svg.gradientStop(0, "red", 'width="100" height="100"'), "gradientStop-with-props");
        _validateSvgElement(svg.gradientStop(0, "red", ""), "gradientStop-no-props");
    }

    function testAnimateTransform() public {
        _validateSvgElement(svg.animateTransform('width="100" height="100"'), "animateTransform-with-props");
        _validateSvgElement(svg.animateTransform(""), "animateTransform-no-props");
    }

    function testImage() public {
        _validateSvgElement(svg.image("https://example.com", 'width="100" height="100"'), "image-with-props");
        _validateSvgElement(svg.image("https://example.com", ""), "image-no-props");
    }

    function testEl() public {
        _validateSvgElement(
            svg.el("rect", 'width="100" height="100"', '<circle width="100" height="100"></circle>'),
            "el-with-props-and-children"
        );
        _validateSvgElement(svg.el("rect", 'width="100" height="100"', ""), "el-with-props");
        _validateSvgElement(svg.el("rect", "", ""), "el-no-props");
    }

    function testElNoChildren() public {
        _validateSvgElement(svg.el("rect", 'width="100" height="100"'), "el-no-children-with-props");
        _validateSvgElement(svg.el("rect", ""), "el-no-children-no-props");
    }

    function testProp() public {
        string memory prop = svg.prop("width", "100");
        _validateSvgElement(svg.el("rect", prop, ""), "prop");
    }

    ////////////////////////////////////////////////////////////////////////////
    //                          Helpers                                       //
    ////////////////////////////////////////////////////////////////////////////

    function _validateTopLevelSvg(string memory libOutput, string memory fileName) internal {
        // Write the svg to a file.
        vm.writeFile(string(abi.encodePacked(TEMP_SVG_DIR_PATH_AND_PREFIX, fileName, TEMP_SVG_FILE_TYPE)), libOutput);

        // Validate the svg.
        _validateSvg(fileName);
    }

    function _validateSvgElement(string memory libOutput, string memory fileName) internal {
        // Wrap the svg element in a top level svg call.
        libOutput = svg.top("", libOutput);

        // Validate the svg.
        _validateTopLevelSvg(libOutput, fileName);
    }

    function _validateSvg(string memory fileName) internal {
        string memory filePath = string(abi.encodePacked(TEMP_SVG_DIR_PATH_AND_PREFIX, fileName, TEMP_SVG_FILE_TYPE));

        // Run the validate_svg.js script on the file to validate the svg.
        string[] memory commandLineInputs = new string[](3);
        commandLineInputs[0] = "node";
        commandLineInputs[1] = VALIDATE_SVG_PATH;
        commandLineInputs[2] = filePath;

        (bool isValid, string memory svg) = abi.decode(vm.ffi(commandLineInputs), (bool, string));

        assertEq(isValid, true, string(abi.encodePacked("The svg should be valid. Invalid svg: ", svg)));

        _cleanUp(filePath);
    }

    function _populateTempFileWithJson(uint256 tokenId) internal {
        // Get the raw URI response.
        string memory rawUri = testExampleNft.tokenURI(tokenId);

        // Write the decoded json to a file.
        vm.writeFile(TEMP_JSON_PATH, rawUri);
    }

    function _getImage() internal returns (string memory) {
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

        (,, string memory image) = abi.decode(vm.ffi(commandLineInputs), (string, string, string));

        _cleanUp(TEMP_JSON_PATH);

        return string(Base64.decode(_cleanedSvg(image)));
    }

    function _cleanedSvg(string memory uri) internal pure returns (string memory) {
        uint256 stringLength;

        // Get the length of the string from the abi encoded version.
        assembly {
            stringLength := mload(uri)
        }

        // Remove the "data:image/svg+xml;base64," prefix.
        return _substring(uri, 26, stringLength);
    }

    function _substring(string memory str, uint256 startIndex, uint256 endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);

        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _cleanUp(string memory file) internal {
        if (vm.exists(file)) {
            vm.removeFile(file);
        }
        assertFalse(vm.exists(file));
    }
}
