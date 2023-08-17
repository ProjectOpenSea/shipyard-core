//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {LibString} from "solady/utils/LibString.sol";

/**
 * @title Core SVG utilitiy library which helps us construct SVG's with a simple, web-like API.
 * @author w1nt3r.eth
 * @notice Modified from w1nt3r.eth's hot-chain-svg library: https://github.com/w1nt3r-eth/hot-chain-svg
 */
library svg {
    using LibString for uint256;

    // used to simulate empty strings
    string internal constant NULL = "";

    function svg_(bool includeXmlns, string memory props, string memory children)
        internal
        pure
        returns (string memory)
    {
        if (includeXmlns) {
            return el("svg", string.concat('xmlns="http://www.w3.org/2000/svg" ', props), children);
        } else {
            return el("svg", props, children);
        }
    }

    function g(string memory props, string memory children) internal pure returns (string memory) {
        return el("g", props, children);
    }

    function path(string memory props, string memory children) internal pure returns (string memory) {
        return el("path", props, children);
    }

    function text(string memory props, string memory children) internal pure returns (string memory) {
        return el("text", props, children);
    }

    function line(string memory props, string memory children) internal pure returns (string memory) {
        return el("line", props, children);
    }

    function circle(string memory props, string memory children) internal pure returns (string memory) {
        return el("circle", props, children);
    }

    function circle(string memory props) internal pure returns (string memory) {
        return el("circle", props);
    }

    function rect(string memory props, string memory children) internal pure returns (string memory) {
        return el("rect", props, children);
    }

    function rect(string memory props) internal pure returns (string memory) {
        return el("rect", props);
    }

    function filter(string memory props, string memory children) internal pure returns (string memory) {
        return el("filter", props, children);
    }

    function cdata(string memory content) internal pure returns (string memory) {
        return string.concat("<![CDATA[", content, "]]>");
    }

    /* GRADIENTS */
    function radialGradient(string memory props, string memory children) internal pure returns (string memory) {
        return el("radialGradient", props, children);
    }

    function linearGradient(string memory props, string memory children) internal pure returns (string memory) {
        return el("linearGradient", props, children);
    }

    function gradientStop(uint256 offset, string memory stopColor, string memory props)
        internal
        pure
        returns (string memory)
    {
        return el(
            "stop",
            string.concat(
                prop("stop-color", stopColor), " ", prop("offset", string.concat(offset.toString(), "%")), " ", props
            )
        );
    }

    function animateTransform(string memory props) internal pure returns (string memory) {
        return el("animateTransform", props);
    }

    function image(string memory href, string memory props) internal pure returns (string memory) {
        return el("image", string.concat(prop("href", href), " ", props));
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(string memory tag, string memory props, string memory children) internal pure returns (string memory) {
        return string.concat("<", tag, " ", props, ">", children, "</", tag, ">");
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(string memory tag, string memory props) internal pure returns (string memory) {
        return string.concat("<", tag, " ", props, "/>");
    }

    // an SVG attribute
    function prop(string memory key, string memory val) internal pure returns (string memory) {
        return string.concat(key, "=", '"', val, '" ');
    }

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory key, string memory val) internal pure returns (string memory) {
        return string.concat("--", key, ":", val, ";");
    }

    // formats getting a css variable
    function getCssVar(string memory key) internal pure returns (string memory) {
        return string.concat("var(--", key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory id) internal pure returns (string memory) {
        return string.concat("url(#", id, ")");
    }

    // formats generic rgba color in css
    function rgba(uint256 r, uint256 g, uint256 b, uint256 a) internal pure returns (string memory) {
        string memory formattedA = a < 100 ? string.concat("0.", a.toString()) : "1";
        return string.concat("rgba(", r.toString(), ",", g.toString(), ",", b.toString(), ",", formattedA, ")");
    }
}
