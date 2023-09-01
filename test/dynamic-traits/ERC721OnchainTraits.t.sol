// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ExampleNFT, DynamicTraits} from "src/reference/ExampleNFT.sol";
import {
    TraitLabelHelpers,
    TraitLabelStorage,
    TraitLabel,
    Editors,
    StoredTraitLabel,
    AllowedEditor,
    FullTraitValue
} from "src/dynamic-traits/TraitLabelHelpers.sol";
import {DisplayType} from "src/onchain/Metadata.sol";

contract Debug is ExampleNFT {
    function getStringURI(uint256 tokenId) public view returns (string memory) {
        return stringURI(tokenId);
    }
}

contract ERC721OnchainTraitsTest is Test, TraitLabelHelpers {
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
        (Editors editors, bool required, bool shouldValidate, StoredTraitLabel storedlabel) =
            token.traitLabelStorage(bytes32("test.key"));
        assertEq(Editors.unwrap(editors), Editors.unwrap(label.editors));
        assertEq(required, label.required);
        assertEq(shouldValidate, false);
        TraitLabel memory retrieved = load(storedlabel);
        assertEq(label, retrieved);
    }

    function testGetTraitLabelsURI() public {
        _setLabel();
        assertEq(
            token.getTraitLabelsURI(),
            'data:application/json;[{"traitKey":"test.key","fullTraitKey":"","traitLabel":"Trait Key","acceptableValues":[],"fullTraitValues":[],"displayType":"string","editors":[0],"required":"false"}]'
        );
    }

    function testSetTrait() public {
        _setLabel();
        // TODO: should token have to exist?
        token.setTrait(bytes32("test.key"), 1, bytes32("foo"));
        assertEq(token.getTraitValue(bytes32("test.key"), 1), bytes32("foo"));

        token.clearTrait(bytes32("test.key"), 1);
        vm.expectRevert(abi.encodeWithSelector(DynamicTraits.TraitNotSet.selector, 1, bytes32("test.key")));
        token.getTraitValue(bytes32("test.key"), 1);
    }

    function testStringURI() public {
        _setLabel();
        token.mint(address(this));
        token.setTrait(bytes32("test.key"), 1, bytes32("foo"));
        assertEq(token.getTraitValue(bytes32("test.key"), 1), bytes32("foo"));
        assertEq(
            token.getStringURI(1),
            '{"name":"Example NFT #1","description":"This is an example NFT","image":"data:image/svg+xml;<svg xmlns=\\\\\\"http://www.w3.org/2000/svg\\\\\\" width=\\\\\\"500\\\\\\" height=\\\\\\"500\\\\\\" ><rect width=\\\\\\"500\\\\\\" height=\\\\\\"500\\\\\\" fill=\\\\\\"lightgray\\\\\\" /><text x=\\\\\\"50%\\\\\\" y=\\\\\\"50%\\\\\\" dominant-baseline=\\\\\\"middle\\\\\\" text-anchor=\\\\\\"middle\\\\\\" font-size=\\\\\\"48\\\\\\" fill=\\\\\\"black\\\\\\" >1</text></svg>","attributes":[{"trait_type":"Example Attribute","value":"Example Value"},{"trait_type":"Number","value":"1","display_type":"number"},{"trait_type":"Parity","value":"Odd"},{"trait_type":"Trait Key","value":"foo","display_type":"string"}]}'
        );
    }

    function _setLabel() internal returns (TraitLabel memory) {
        TraitLabel memory label = TraitLabel({
            fullTraitKey: "",
            traitLabel: "Trait Key",
            acceptableValues: new string[](0),
            fullTraitValues: new FullTraitValue[](0),
            displayType: DisplayType.String,
            editors: Editors.wrap(toBitMap(AllowedEditor.Anyone)),
            required: false
        });
        token.setTraitLabel(bytes32("test.key"), label);
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
        string memory x = toString(bytes32("foo"));
        assertEq(x, "foo");
        x = toString(bytes32("the string is 32 characters long"));
        assertEq(x, "the string is 32 characters long");
    }

    function testEditorsAggregateExpand() public {
        AllowedEditor[] memory editors = new AllowedEditor[](4);
        editors[0] = AllowedEditor.Self;
        editors[1] = AllowedEditor.TokenOwner;
        editors[2] = AllowedEditor.Custom;
        editors[3] = AllowedEditor.ContractOwner;
        Editors aggregated = aggregate(editors);
        AllowedEditor[] memory expanded = expand(aggregated);
        assertEq(keccak256(abi.encode(editors)), keccak256(abi.encode(expanded)));

        editors = new AllowedEditor[](2);
        editors[0] = AllowedEditor.Self;
        editors[1] = AllowedEditor.TokenOwner;
        aggregated = aggregate(editors);
        expanded = expand(aggregated);
        assertEq(keccak256(abi.encode(editors)), keccak256(abi.encode(expanded)));
    }
}
