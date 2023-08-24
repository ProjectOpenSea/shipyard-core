// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {svg} from "../../src/onchain/svg.sol";

contract svgTest is Test {
    function testTop() public {
        string memory expected =
            '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><circle width="100" height="100"/></svg>';
        string memory actual = svg.top('width="100" height="100"', '<circle width="100" height="100"/>');

        assertEq(expected, actual);

        expected = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"></svg>';
        actual = svg.top('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = '<svg xmlns="http://www.w3.org/2000/svg" ></svg>';
        actual = svg.top("", "");

        assertEq(expected, actual);
    }

    function testSvg() public {
        string memory expected =
            '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><circle width="100" height="100"/></svg>';
        string memory actual = svg.svg_(true, 'width="100" height="100"', '<circle width="100" height="100"/>');

        assertEq(expected, actual);

        expected = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"></svg>';
        actual = svg.svg_(true, 'width="100" height="100"', "");

        assertEq(expected, actual);

        expected = '<svg width="100" height="100"></svg>';
        actual = svg.svg_(false, 'width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<svg ></svg>";
        actual = svg.svg_(false, "", "");

        assertEq(expected, actual);
    }

    function testG() public {
        string memory expected = '<g width="100" height="100"><circle width="100" height="100"></circle></g>';
        string memory actual = svg.g('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<g width="100" height="100"></g>';
        actual = svg.g('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<g ></g>";
        actual = svg.g("", "");

        assertEq(expected, actual);
    }

    function testPath() public {
        string memory expected = '<path width="100" height="100"><circle width="100" height="100"></circle></path>';
        string memory actual = svg.path('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<path width="100" height="100"></path>';
        actual = svg.path('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<path ></path>";
        actual = svg.path("", "");

        assertEq(expected, actual);
    }

    function testText() public {
        string memory expected = '<text width="100" height="100"><circle width="100" height="100"></circle></text>';
        string memory actual = svg.text('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<text width="100" height="100"></text>';
        actual = svg.text('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<text ></text>";
        actual = svg.text("", "");

        assertEq(expected, actual);
    }

    function testLine() public {
        string memory expected = '<line width="100" height="100"><circle width="100" height="100"></circle></line>';
        string memory actual = svg.line('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<line width="100" height="100"></line>';
        actual = svg.line('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<line ></line>";
        actual = svg.line("", "");

        assertEq(expected, actual);
    }

    function testCircle() public {
        string memory expected = '<circle width="100" height="100"><circle width="100" height="100"></circle></circle>';
        string memory actual = svg.circle('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<circle width="100" height="100"></circle>';
        actual = svg.circle('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<circle ></circle>";
        actual = svg.circle("", "");
    }

    function testCircleNoChildren() public {
        string memory expected = '<circle width="100" height="100"/>';
        string memory actual = svg.circle('width="100" height="100"');

        assertEq(expected, actual);

        expected = "<circle />";
        actual = svg.circle("");

        assertEq(expected, actual);
    }

    function testRect() public {
        string memory expected = '<rect width="100" height="100"><circle width="100" height="100"></circle></rect>';
        string memory actual = svg.rect('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<rect width="100" height="100"></rect>';
        actual = svg.rect('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<rect ></rect>";
        actual = svg.rect("", "");

        assertEq(expected, actual);
    }

    function testRectNoChildren() public {
        string memory expected = '<rect width="100" height="100"/>';
        string memory actual = svg.rect('width="100" height="100"');

        assertEq(expected, actual);

        expected = "<rect />";
        actual = svg.rect("");

        assertEq(expected, actual);
    }

    function testFilter() public {
        string memory expected = '<filter width="100" height="100"><circle width="100" height="100"></circle></filter>';
        string memory actual = svg.filter('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<filter width="100" height="100"></filter>';
        actual = svg.filter('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<filter ></filter>";
        actual = svg.filter("", "");
    }

    function testCdata() public {
        string memory expected = "<![CDATA[<svg></svg>]]>";
        string memory actual = svg.cdata("<svg></svg>");

        assertEq(expected, actual);
    }

    function testRadialGradient() public {
        string memory expected =
            '<radialGradient width="100" height="100"><circle width="100" height="100"></circle></radialGradient>';
        string memory actual =
            svg.radialGradient('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<radialGradient width="100" height="100"></radialGradient>';
        actual = svg.radialGradient('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<radialGradient ></radialGradient>";
        actual = svg.radialGradient("", "");
    }

    function testLinearGradient() public {
        string memory expected =
            '<linearGradient width="100" height="100"><circle width="100" height="100"></circle></linearGradient>';
        string memory actual =
            svg.linearGradient('width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<linearGradient width="100" height="100"></linearGradient>';
        actual = svg.linearGradient('width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<linearGradient ></linearGradient>";
        actual = svg.linearGradient("", "");
    }

    function testGradientStop() public {
        string memory expected = '<stop stop-color="red" offset="0%" width="100" height="100"/>';
        string memory actual = svg.gradientStop(0, "red", 'width="100" height="100"');

        assertEq(expected, actual);

        expected = '<stop stop-color="red" offset="0%" />';
        actual = svg.gradientStop(0, "red", "");

        assertEq(expected, actual);
    }

    function testAnimateTransform() public {
        string memory expected = '<animateTransform width="100" height="100"/>';
        string memory actual = svg.animateTransform('width="100" height="100"');

        assertEq(expected, actual);

        expected = "<animateTransform />";
        actual = svg.animateTransform("");

        assertEq(expected, actual);
    }

    function testImage() public {
        string memory expected = '<image href="https://example.com" width="100" height="100"/>';
        string memory actual = svg.image("https://example.com", 'width="100" height="100"');

        assertEq(expected, actual);

        expected = '<image href="https://example.com" />';
        actual = svg.image("https://example.com", "");

        assertEq(expected, actual);
    }

    function testEl() public {
        string memory expected = '<rect width="100" height="100"><circle width="100" height="100"></circle></rect>';
        string memory actual = svg.el("rect", 'width="100" height="100"', '<circle width="100" height="100"></circle>');

        assertEq(expected, actual);

        expected = '<rect width="100" height="100"></rect>';
        actual = svg.el("rect", 'width="100" height="100"', "");

        assertEq(expected, actual);

        expected = "<rect ></rect>";
        actual = svg.el("rect", "", "");

        assertEq(expected, actual);
    }

    function testElNoChildren() public {
        string memory expected = '<rect width="100" height="100"/>';
        string memory actual = svg.el("rect", 'width="100" height="100"');

        assertEq(expected, actual);

        expected = "<rect />";
        actual = svg.el("rect", "");

        assertEq(expected, actual);
    }

    function testProp() public {
        string memory expected = 'width="100" ';
        string memory actual = svg.prop("width", "100");

        assertEq(expected, actual);
    }

    function testSetCssVar() public {
        string memory expected = "--width:100;";
        string memory actual = svg.setCssVar("width", "100");

        assertEq(expected, actual);
    }

    function testGetCssVar() public {
        string memory expected = "var(--width)";
        string memory actual = svg.getCssVar("width");

        assertEq(expected, actual);
    }

    function testGetDefURL() public {
        string memory expected = "url(#id)";
        string memory actual = svg.getDefURL("id");

        assertEq(expected, actual);
    }

    function testRgba() public {
        string memory expected = "rgba(100,100,100,0.1)";
        string memory actual = svg.rgba(100, 100, 100, 1);

        assertEq(expected, actual);

        expected = "rgba(100,100,100,1)";
        actual = svg.rgba(100, 100, 100, 100);

        assertEq(expected, actual);
    }
}
