// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {json} from "./json.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Solarray} from "solarray/Solarray.sol";
import {Base64} from "solady/utils/Base64.sol";

enum DisplayType {
    String,
    Number,
    Date,
    BoostPercent,
    BoostNumber
}

library Metadata {
    string private constant NULL = "";

    using LibString for string;

    function attribute(string memory traitType, string memory value) internal pure returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("trait_type", traitType).escapeJSON(), json.property("value", value).escapeJSON()
            )
        );
    }

    function attribute(string memory traitType, string memory value, DisplayType displayType)
        internal
        pure
        returns (string memory)
    {
        return json.objectOf(
            Solarray.strings(
                json.property("trait_type", traitType).escapeJSON(),
                json.property("value", value).escapeJSON(),
                json.property("display_type", _toString(displayType))
            )
        );
    }

    function _toString(DisplayType displayType) internal pure returns (string memory) {
        if (displayType == DisplayType.String) {
            return "string";
        } else if (displayType == DisplayType.Number) {
            return "number";
        } else if (displayType == DisplayType.Date) {
            return "date";
        } else if (displayType == DisplayType.BoostNumber) {
            return "boost_number";
        } /*if (displayType == DisplayType.BoostPercent)*/ else {
            return "boost_percent";
        }
    }

    function dataURI(string memory dataType, string memory encoding, string memory content)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            "data:", dataType, ";", bytes(encoding).length > 0 ? string.concat(encoding, ",") : NULL, content
        );
    }

    function dataURI(string memory dataType, string memory content) internal pure returns (string memory) {
        return dataURI(dataType, NULL, content);
    }

    function jsonDataURI(string memory content, string memory encoding) internal pure returns (string memory) {
        return dataURI("application/json", encoding, content);
    }

    function jsonDataURI(string memory content) internal pure returns (string memory) {
        return jsonDataURI(content, NULL);
    }

    function base64JsonDataURI(string memory content) internal pure returns (string memory) {
        return jsonDataURI(Base64.encode(bytes(content)), "base64");
    }

    function svgDataURI(string memory content, string memory encoding) internal pure returns (string memory) {
        return dataURI("image/svg+xml", encoding, content).escapeJSON();
    }

    function svgDataURI(string memory content) internal pure returns (string memory) {
        return svgDataURI(content, NULL);
    }
}
