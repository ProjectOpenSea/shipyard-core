// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AbstractDynamicTraits} from "../dynamic-traits/AbstractDynamicTraits.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {ERC721SeaDrop} from "../seadrop/ERC721SeaDrop.sol";
import {IERC7498} from "./interfaces/IERC7498.sol";
import {OfferItem, ConsiderationItem, SpentItem} from "seaport-types/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/lib/ConsiderationEnums.sol";
import {IERC721RedemptionMintable} from "./interfaces/IERC721RedemptionMintable.sol";
import {CampaignParams, TraitRedemption} from "./lib/RedeemablesStructs.sol";
import {RedeemablesErrorsAndEvents} from "./lib/RedeemablesErrorsAndEvents.sol";

contract ERC7498NFTRedeemables is ERC721SeaDrop, IERC7498, RedeemablesErrorsAndEvents {
    /// @dev Counter for next campaign id.
    uint256 private _nextCampaignId = 1;

    /// @dev The campaign parameters by campaign id.
    mapping(uint256 campaignId => CampaignParams params) private _campaignParams;

    /// @dev The campaign URIs by campaign id.
    mapping(uint256 campaignId => string campaignURI) private _campaignURIs;

    /// @dev The total current redemptions by campaign id.
    mapping(uint256 campaignId => uint256 count) private _totalRedemptions;

    constructor(address[] memory allowedSeaDrop) ERC721SeaDrop("ERC7498 NFT Redeemables", "NFTR", allowedSeaDrop) {}

    function name() public pure override returns (string memory) {
        return "ERC7498 NFT Redeemables";
    }

    function symbol() public pure override returns (string memory) {
        return "NFTR";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return "https://example.com/";
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    // at 64 will be pointer to array
    // mload pointer, pointer points to length
    // next word is start of array
    function redeem(uint256[] calldata tokenIds, address recipient, bytes calldata extraData) public virtual override {
        // Get the campaign id from extraData.
        uint256 campaignId = uint256(bytes32(extraData[0:32]));

        // Get the campaign params.
        CampaignParams storage params = _campaignParams[campaignId];

        // Revert if campaign is inactive.
        if (_isInactive(params.startTime, params.endTime)) {
            revert NotActive(block.timestamp, params.startTime, params.endTime);
        }

        // Revert if max total redemptions would be exceeded.
        if (_totalRedemptions[campaignId] + tokenIds.length > params.maxCampaignRedemptions) {
            revert MaxCampaignRedemptionsReached(_totalRedemptions[campaignId] + 1, params.maxCampaignRedemptions);
        }

        // Get the campaign consideration.
        ConsiderationItem[] memory consideration = params.consideration;

        // TraitRedemption[] calldata traitRedemptions;

        // // calldata array is two vars on stack (length, ptr to start of array)
        // assembly {
        //     // Get the pointer to the length of the trait redemptions array by adding 0x40 to the extraData offset.
        //     let traitRedemptionsLengthPtr := calldataload(add(0x40, extraData.offset))

        //     // Set the length of the trait redeptions array to the value at the array length pointer.
        //     traitRedemptions.length := calldataload(traitRedemptionsLengthPtr)

        //     // Set the pointer to the start of the trait redemptions array to the word after the length.
        //     traitRedemptions.offset := add(0x20, traitRedemptionsLengthPtr)
        // }

        // // Iterate over the trait redemptions and set traits on the tokens.
        // for (uint256 i; i < traitRedemptions.length;) {
        //     // Get the trait redemption token address and place on the stack.
        //     address token = traitRedemptions[i].token;

        //     uint256 identifier = traitRedemptions[i].identifier;

        //     // Revert if the trait redemption token is not this token contract.
        //     if (token != address(this)) {
        //         revert InvalidToken(token);
        //     }

        //     // Revert if the trait redemption identifier is not owned by the caller.
        //     if (ERC721(token).ownerOf(identifier) != msg.sender) {
        //         revert InvalidCaller(token);
        //     }

        //     // Declare a new block to manage stack depth.
        //     {
        //         // Get the substandard and place on the stack.
        //         uint8 substandard = traitRedemptions[i].substandard;

        //         // Get the substandard value and place on the stack.
        //         bytes32 substandardValue = traitRedemptions[i].substandardValue;

        //         // Get the trait key and place on the stack.
        //         bytes32 traitKey = traitRedemptions[i].traitKey;

        //         bytes32 traitValue = traitRedemptions[i].traitValue;

        //         // Get the current trait value and place on the stack.
        //         bytes32 currentTraitValue = getTraitValue(traitKey, identifier);

        //         // If substandard is 1, set trait to traitValue.
        //         if (substandard == 1) {
        //             // Revert if the current trait value does not match the substandard value.
        //             if (currentTraitValue != substandardValue) {
        //                 revert InvalidRequiredValue(currentTraitValue, substandardValue);
        //             }

        //             // Set the trait to the trait value.
        //             _setTrait(traitRedemptions[i].traitKey, identifier, traitValue);
        //             // If substandard is 2, increment trait by traitValue.
        //         } else if (substandard == 2) {
        //             // Revert if the current trait value is greater than the substandard value.
        //             if (currentTraitValue > substandardValue) {
        //                 revert InvalidRequiredValue(currentTraitValue, substandardValue);
        //             }

        //             // Increment the trait by the trait value.
        //             uint256 newTraitValue = uint256(currentTraitValue) + uint256(traitValue);

        //             _setTrait(traitRedemptions[i].traitKey, identifier, bytes32(newTraitValue));
        //         } else if (substandard == 3) {
        //             // Revert if the current trait value is less than the substandard value.
        //             if (currentTraitValue < substandardValue) {
        //                 revert InvalidRequiredValue(currentTraitValue, substandardValue);
        //             }

        //             uint256 newTraitValue = uint256(currentTraitValue) - uint256(traitValue);

        //             // Decrement the trait by the trait value.
        //             _setTrait(traitRedemptions[i].traitKey, traitRedemptions[i].identifier, bytes32(newTraitValue));
        //         }
        //     }
        //     unchecked {
        //         ++i;
        //     }
        // }

        // Iterate over the token IDs and check if caller is the owner or approved operator.
        // Redeem the token if the caller is valid.
        for (uint256 i; i < tokenIds.length;) {
            // Get the identifier.
            uint256 identifier = tokenIds[i];

            // Get the token owner.
            address owner = ownerOf(identifier);

            // Check the caller is either the owner or approved operator.
            if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
                revert InvalidCaller(msg.sender);
            }

            // Burn or transfer the token to the consideration recipient.
            if (consideration[0].recipient == payable(address(0x000000000000000000000000000000000000dEaD))) {
                _burn(identifier);
            } else {
                ERC721(consideration[0].token).safeTransferFrom(owner, consideration[0].recipient, identifier);
            }

            // Mint the redemption token.
            IERC721RedemptionMintable(params.offer[0].token).mintRedemption(recipient, identifier);

            unchecked {
                ++i;
            }
        }
    }

    function getCampaign(uint256 campaignId)
        external
        view
        override
        returns (CampaignParams memory params, string memory uri, uint256 totalRedemptions)
    {
        // Revert if campaign id is invalid.
        if (campaignId >= _nextCampaignId) revert InvalidCampaignId();

        // Get the campaign params.
        params = _campaignParams[campaignId];

        // Get the campaign URI.
        uri = _campaignURIs[campaignId];

        // Get the total redemptions.
        totalRedemptions = _totalRedemptions[campaignId];
    }

    function createCampaign(CampaignParams calldata params, string calldata uri)
        external
        override
        returns (uint256 campaignId)
    {
        // Revert if there are no consideration items, since the redemption should require at least something.
        if (params.consideration.length == 0) revert NoConsiderationItems();

        // Revert if startTime is past endTime.
        if (params.startTime > params.endTime) revert InvalidTime();

        // Revert if any of the consideration item recipients is the zero address. The 0xdead address should be used instead.
        for (uint256 i = 0; i < params.consideration.length;) {
            if (params.consideration[i].recipient == address(0)) {
                revert ConsiderationItemRecipientCannotBeZeroAddress();
            }
            unchecked {
                ++i;
            }
        }

        // Set the campaign params for the next campaignId.
        _campaignParams[_nextCampaignId] = params;

        // Set the campaign URI for the next campaignId.
        _campaignURIs[_nextCampaignId] = uri;

        // Set the correct current campaignId to return before incrementing
        // the next campaignId.
        campaignId = _nextCampaignId;

        // Increment the next campaignId.
        _nextCampaignId++;

        emit CampaignUpdated(campaignId, params, _campaignURIs[campaignId]);
    }

    function updateCampaign(uint256 campaignId, CampaignParams calldata params, string calldata uri)
        external
        override
    {
        // Revert if campaign id is invalid.
        if (campaignId == 0 || campaignId >= _nextCampaignId) {
            revert InvalidCampaignId();
        }

        // Revert if there are no consideration items, since the redemption should require at least something.
        if (params.consideration.length == 0) revert NoConsiderationItems();

        // Revert if startTime is past endTime.
        if (params.startTime > params.endTime) revert InvalidTime();

        // Revert if msg.sender is not the manager.
        address existingManager = _campaignParams[campaignId].manager;
        if (params.manager != msg.sender && (existingManager != address(0) && existingManager != params.manager)) {
            revert NotManager();
        }

        // Revert if any of the consideration item recipients is the zero address. The 0xdead address should be used instead.
        for (uint256 i = 0; i < params.consideration.length;) {
            if (params.consideration[i].recipient == address(0)) {
                revert ConsiderationItemRecipientCannotBeZeroAddress();
            }
            unchecked {
                ++i;
            }
        }

        // Set the campaign params for the given campaignId.
        _campaignParams[campaignId] = params;

        // Update campaign uri if it was provided.
        if (bytes(uri).length != 0) {
            _campaignURIs[campaignId] = uri;
        }

        emit CampaignUpdated(campaignId, params, _campaignURIs[campaignId]);
    }

    function _isInactive(uint256 startTime, uint256 endTime) internal view returns (bool inactive) {
        // Using the same check for time boundary from Seaport.
        // startTime <= block.timestamp < endTime
        assembly {
            inactive := or(iszero(gt(endTime, timestamp())), gt(startTime, timestamp()))
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721SeaDrop) returns (bool) {
        return interfaceId == type(IERC7498).interfaceId || super.supportsInterface(interfaceId);
    }
}
