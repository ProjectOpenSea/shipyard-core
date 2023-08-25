// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ERC721ConduitPreapproved_Solady, ERC721
} from "shipyard-core/tokens/erc721/ERC721ConduitPreapproved_Solady.sol";
import {json} from "shipyard-core/onchain/json.sol";
import {svg} from "shipyard-core/onchain/svg.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Solarray} from "solarray/Solarray.sol";
import {Metadata, DisplayType} from "shipyard-core/onchain/Metadata.sol";
import {OnchainTraits, DynamicTraits} from "shipyard-core/dynamic-traits/OnchainTraits.sol";

contract ExampleNFT is OnchainTraits, ERC721ConduitPreapproved_Solady {
    using LibString for string;
    using LibString for uint256;

    uint256 currentId;

    function name() public pure override returns (string memory) {
        return "ExampleNFT";
    }

    function symbol() public pure override returns (string memory) {
        return "EXNFT";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return Metadata.base64JsonDataURI(stringURI(tokenId));
    }

    function stringURI(uint256 tokenId) internal view returns (string memory) {
        return json.objectOf(
            Solarray.strings(
                json.property("name", string.concat("Example NFT #", tokenId.toString())),
                json.property("description", "This is an example NFT"),
                json.property("image", Metadata.svgDataURI(image(tokenId))),
                _attribute(tokenId)
            )
        );
    }

    // @dev Split out from the stringURI function to allow compiling with the
    // optimizer off / without via-IR.
    function _attribute(uint256 tokenId) internal view returns (string memory) {
        string[] memory staticTraits = Solarray.strings(
            Metadata.attribute({traitType: "Example Attribute", value: "Example Value"}),
            Metadata.attribute({traitType: "Number", value: tokenId.toString(), displayType: DisplayType.Number}),
            Metadata.attribute({traitType: "Parity", value: tokenId % 2 == 0 ? "Even" : "Odd"})
        );
        string[] memory dynamicTraits = _dynamicAttributes(tokenId);
        string[] memory combined = new string[](staticTraits.length + dynamicTraits.length);
        for (uint256 i = 0; i < staticTraits.length; i++) {
            combined[i] = staticTraits[i];
        }
        for (uint256 i = 0; i < dynamicTraits.length; i++) {
            combined[staticTraits.length + i] = dynamicTraits[i];
        }
        return json.rawProperty("attributes", json.arrayOf(combined));
    }

    function image(uint256 tokenId) internal pure returns (string memory) {
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
                    children: tokenId.toString()
                })
                )
        });
    }

    function mint(address to) public {
        unchecked {
            _mint(to, ++currentId);
        }
    }

    function isOwnerOrApproved(uint256 tokenId, address addr) public view virtual override returns (bool) {
        return ownerOf(tokenId) == addr || getApproved(tokenId) == addr || isApprovedForAll(ownerOf(tokenId), addr);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(DynamicTraits, ERC721) returns (bool) {
        return DynamicTraits.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }
}
