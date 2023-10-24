// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ExampleNFT} from "src/reference/ExampleNFT.sol";
import {DynamicTraits} from "src/dynamic-traits/ERC721OnchainTraits.sol";
import {
    TraitLabelStorage,
    TraitLabelStorageLib,
    TraitLabel,
    TraitLabelLib,
    Editors,
    FullTraitValue,
    StoredTraitLabel,
    AllowedEditor,
    TraitLib,
    StoredTraitLabelLib,
    EditorsLib
} from "src/dynamic-traits/lib/TraitLabelLib.sol";
import {DisplayType} from "src/onchain/Metadata.sol";

contract Debug is ExampleNFT("Example", "EXNFT") {
    function getStringURI(uint256 tokenId) public view returns (string memory) {
        return _stringURI(tokenId);
    }
}

contract ERC721OnchainTraitsTest is Test {
    Debug token;

    function setUp() public {
        token = new Debug();
    }

    function testUpdateCustomEditor() public {
        assertFalse(token.isCustomEditor(address(this)));

        token.updateCustomEditor(address(this), true);
        assertTrue(token.isCustomEditor(address(this)));
        token.updateCustomEditor(address(this), false);
        assertFalse(token.isCustomEditor(address(this)));
    }

    function testGetCustomEditorsLength() public {
        assertEq(token.getCustomEditorsLength(), 0);

        token.updateCustomEditor(address(this), true);
        assertEq(token.getCustomEditorsLength(), 1);
        token.updateCustomEditor(address(1234), true);
        assertEq(token.getCustomEditorsLength(), 2);
    }

    function testGetCustomEditors() public {
        token.updateCustomEditor(address(this), true);
        token.updateCustomEditor(address(1234), true);

        address[] memory editors = token.getCustomEditors();
        assertEq(editors.length, 2);
        assertEq(editors[0], address(this));
        assertEq(editors[1], address(1234));
    }

    function testGetCustomEditorAt() public {
        token.updateCustomEditor(address(this), true);
        token.updateCustomEditor(address(1234), true);

        assertEq(token.getCustomEditorAt(0), address(this));
        assertEq(token.getCustomEditorAt(1), address(1234));
    }

    function testGetTraitLabel() public {
        TraitLabel memory label = _setLabel();
        TraitLabelStorage memory storage_ = token.traitLabelStorage(bytes32("testKey"));
        assertEq(Editors.unwrap(storage_.allowedEditors), Editors.unwrap(label.editors));
        assertEq(storage_.required, label.required);
        assertEq(storage_.valuesRequireValidation, false);
        TraitLabel memory retrieved = StoredTraitLabelLib.load(storage_.storedLabel);
        assertEq(label, retrieved);
    }

    function testGetTraitLabelsURI() public {
        _setLabel();
        assertEq(
            token.getTraitMetadataURI(),
            'data:application/json;[{"traitKey":"testKey","fullTraitKey":"testKey","traitLabel":"Trait Key","acceptableValues":[],"fullTraitValues":[],"displayType":"string","editors":[0]}]'
        );
    }

    function testSetTrait() public {
        _setLabel();
        token.mint(address(this));
        token.setTrait(1, bytes32("testKey"), bytes32("foo"));
        assertEq(token.getTraitValue(1, bytes32("testKey")), bytes32("foo"));
    }

    function testStringURI() public {
        _setLabel();
        token.mint(address(this));
        token.setTrait(1, bytes32("testKey"), bytes32("foo"));
        assertEq(token.getTraitValue(1, bytes32("testKey")), bytes32("foo"));
        assertEq(
            token.getStringURI(1),
            '{"name":"Example NFT #1","description":"This is an example NFT","image":"data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI1MDAiIGhlaWdodD0iNTAwIiA+PHJlY3Qgd2lkdGg9IjUwMCIgaGVpZ2h0PSI1MDAiIGZpbGw9ImxpZ2h0Z3JheSIgLz48dGV4dCB4PSI1MCUiIHk9IjUwJSIgZG9taW5hbnQtYmFzZWxpbmU9Im1pZGRsZSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC1zaXplPSI0OCIgZmlsbD0iYmxhY2siID4xPC90ZXh0Pjwvc3ZnPg==","attributes":[{"trait_type":"Example Attribute","value":"Example Value"},{"trait_type":"Number","value":"1","display_type":"number"},{"trait_type":"Parity","value":"Odd"},{"trait_type":"Trait Key","value":"foo","display_type":"string"}]}'
        );
    }

    function _setLabel() internal returns (TraitLabel memory) {
        TraitLabel memory label = TraitLabel({
            fullTraitKey: "",
            traitLabel: "Trait Key",
            acceptableValues: new string[](0),
            fullTraitValues: new FullTraitValue[](0),
            displayType: DisplayType.String,
            editors: Editors.wrap(EditorsLib.toBitMap(AllowedEditor.Anyone)),
            required: false
        });
        token.setTraitLabel(bytes32("testKey"), label);
        return label;
    }

    function assertEq(TraitLabel memory a, TraitLabel memory b) internal {
        assertEq(a.fullTraitKey, b.fullTraitKey, "fullTraitKey");
        assertEq(a.traitLabel, b.traitLabel, "traitLabel");
        assertEq(keccak256(abi.encode(a.acceptableValues)), keccak256(abi.encode(b.acceptableValues)));
        assertEq(keccak256(abi.encode(a.fullTraitValues)), keccak256(abi.encode(b.fullTraitValues)));
        assertEq(uint8(a.displayType), uint8(b.displayType), "displayType");
        assertEq(Editors.unwrap(a.editors), Editors.unwrap(b.editors), "editors");
        assertEq(a.required, b.required, "required");
    }

    function testBytes32ToString() public {
        string memory x = TraitLib.asString(bytes32("foo"));
        assertEq(x, "foo");
        x = TraitLib.asString(bytes32("a string that's exactly 32 chars"));
        assertEq(x, "a string that's exactly 32 chars");
    }

    function testEditorsAggregateExpand() public {
        AllowedEditor[] memory editors = new AllowedEditor[](4);
        editors[0] = AllowedEditor.Self;
        editors[1] = AllowedEditor.TokenOwner;
        editors[2] = AllowedEditor.Custom;
        editors[3] = AllowedEditor.ContractOwner;
        Editors aggregated = EditorsLib.aggregate(editors);
        AllowedEditor[] memory expanded = EditorsLib.expand(aggregated);
        assertEq(keccak256(abi.encode(editors)), keccak256(abi.encode(expanded)));

        editors = new AllowedEditor[](2);
        editors[0] = AllowedEditor.Self;
        editors[1] = AllowedEditor.TokenOwner;
        aggregated = EditorsLib.aggregate(editors);
        expanded = EditorsLib.expand(aggregated);
        assertTrue(expanded.length == 2, "wrong length");
        assertEq(keccak256(abi.encode(editors)), keccak256(abi.encode(expanded)));
    }
}
