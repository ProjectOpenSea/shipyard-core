// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {json} from "../onchain/json.sol";
import {svg} from "../onchain/svg.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {Solarray} from "solarray/Solarray.sol";
import {Metadata, DisplayType} from "../onchain/Metadata.sol";
import {AbstractNFT} from "./AbstractNFT.sol";

contract ExampleNFT is AbstractNFT {
    uint256 currentId;

    constructor(string memory __name, string memory __symbol) AbstractNFT(__name, __symbol) {}

    function name() public pure override returns (string memory) {
        return "ExampleNFT";
    }

    function symbol() public pure override returns (string memory) {
        return "EXNFT";
    }

    /**
     * @notice Helper function to get the raw JSON metadata representing a given token ID
     * @param tokenId The token ID to get URI for
     */
    function _stringURI(uint256 tokenId) internal view override returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("name", string.concat("Example NFT #", LibString.toString(tokenId))),
                json.property("description", "This is an example NFT"),
                json.property("image", Metadata.base64SvgDataURI(_image(tokenId))),
                _attributes(tokenId)
            )
        );
    }

    /**
     * @notice Helper function to get the static attributes for a given token ID
     * @param tokenId The token ID to get the static attributes for
     */
    function _staticAttributes(uint256 tokenId) internal view virtual override returns (string[] memory) {
        return Solarray.strings(
            Metadata.attribute({traitType: "Example Attribute", value: "Example Value"}),
            Metadata.attribute({
                traitType: "Number",
                value: LibString.toString(tokenId),
                displayType: DisplayType.Number
            }),
            Metadata.attribute({traitType: "Parity", value: tokenId % 2 == 0 ? "Even" : "Odd"})
        );
    }

    /**
     * @notice Helper function to get the raw SVG image for a given token ID
     * @param tokenId The token ID to get the dynamic attributes for
     */
    function _image(uint256 tokenId) internal pure virtual override returns (string memory) {
        return svg.top({
            props: string.concat(svg.prop("width", "500"), svg.prop("height", "500")),
            children: string.concat(
                svg.rect({
                    props: string.concat(svg.prop("width", "500"), svg.prop("height", "500"), svg.prop("fill", "lightgray"))
                }),
                svg.text({
                    props: string.concat(
                        svg.prop("x", "50%"),
                        svg.prop("y", "50%"),
                        svg.prop("dominant-baseline", "middle"),
                        svg.prop("text-anchor", "middle"),
                        svg.prop("font-size", "48"),
                        svg.prop("fill", "black")
                    ),
                    children: LibString.toString(tokenId)
                })
            )
        });
    }

    function mint(address to) public {
        unchecked {
            _mint(to, ++currentId);
        }
    }

    function _isOwnerOrApproved(uint256 tokenId, address addr) internal view virtual override returns (bool) {
        return ownerOf(tokenId) == addr || isApprovedForAll(ownerOf(tokenId), addr) || getApproved(tokenId) == addr;
    }
}
