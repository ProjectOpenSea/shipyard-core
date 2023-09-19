// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721DynamicTraits} from "./ERC721DynamicTraits.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {IERC7498} from "../interfaces/IERC7498.sol";
import {OfferItem, ConsiderationItem, SpentItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {IERC721RedemptionMintable} from "../interfaces/IERC721RedemptionMintable.sol";
import {CampaignParams} from "./RedeemableStructs.sol";
import {RedeemableErrorsAndEvents} from "./RedeemableErrorsAndEvents.sol";

contract ERC7498NFTRedeemables is ERC721DynamicTraits, IERC7498, RedeemableErrorsAndEvents {
    /// @dev Counter for next campaign id.
    uint256 private _nextCampaignId = 1;

    /// @dev The campaign parameters by campaign id.
    mapping(uint256 campaignId => CampaignParams params) private _campaignParams;

    /// @dev The campaign URIs by campaign id.
    mapping(uint256 campaignId => string campaignURI) private _campaignURIs;

    /// @dev The total current redemptions by campaign id.
    mapping(uint256 campaignId => uint256 count) private _totalRedemptions;

    constructor() ERC721 {}

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

    function redeem(uint256[] calldata tokenIds, address recipient, bytes calldata extraData) public virtual {
        // Get the campaign.
        uint256 campaignId = uint256(bytes32(extraData[0:32]));
        CampaignParams storage params = _campaignParams[campaignId];
        ConsiderationItem[] memory consideration = params.consideration;

        // Revert if campaign is inactive.
        if (_isInactive(params.startTime, params.endTime)) {
            revert NotActive(block.timestamp, params.startTime, params.endTime);
        }

        // Revert if max total redemptions would be exceeded.
        if (_totalRedemptions[campaignId] + tokenIds.length > params.maxCampaignRedemptions) {
            revert MaxCampaignRedemptionsReached(_totalRedemptions[campaignId] + 1, params.maxCampaignRedemptions);
        }

        address considerationRecipient;

        for (uint256 i; i < consideration.length;) {
            if (consideration[i].token == address(this)) {
                considerationRecipient = consideration[i].recipient;
            }

            unchecked {
                ++i;
            }
        }

        // TODO: get traitRedemptions from extraData.
        TraitRedemption[] memory traitRedemptions;

        // Iterate over the trait redemptions and set traits on the tokens.
        for (uint256 i; i < traitRedemptions.length;) {
            // Get the trait redemption token address and place on the stack.
            address token = traitRedemptions[i].token;

            uint256 identifier = traitRedemptions[i].identifier;

            // Revert if the trait redemption token is not this token contract.
            if (token != address(this)) {
                revert InvalidToken(token);
            }

            // Revert if the trait redemption identifier is not owned by the caller.
            if (ERC721(token).ownerOf(identifier) != msg.sender) {
                revert InvalidCaller(token);
            }

            // Declare a new block to manage stack depth.
            {
                // Get the substandard and place on the stack.
                uint8 substandard = traitRedemptions[i].substandard;

                // Get the substandard value and place on the stack.
                bytes32 substandardValue = traitRedemptions[i].substandardValue;

                // Get the trait key and place on the stack.
                bytes32 traitKey = traitRedemptions[i].traitKey;

                // Get the current trait value and place on the stack.
                bytes32 currentTraitValue = getTraitValue(traitKey, identifier);

                // If substandard is 1, set trait to traitValue.
                if (substandard == 1) {
                    // Revert if the current trait value does not match the substandard value.
                    if (currentTraitValue != substandardValue) {
                        revert InvalidRequiredValue(existingTraitValue, substandardValue);
                    }

                    // Set the trait to the trait value.
                    _setTrait(
                        traitRedemptions[i].traitKey, traitRedemptions[i].identifier, traitRedemptions[i].traitValue
                    );
                    // If substandard is 2, increment trait by traitValue.
                } else if (substandard == 2) {
                    // Revert if the current trait value is greater than the substandard value.
                    if (currentTraitValue > substandardValue) {
                        revert InvalidRequiredValue(currentTraitValue, substandardValue);
                    }

                    // Increment the trait by the trait value.
                    _setTrait(
                        traitRedemptions[i].traitKey,
                        traitRedemptions[i].identifier,
                        currentTraitValue + traitRedemptions[i].traitValue
                    );
                } else if (substandard == 3) {
                    // Revert if the current trait value is less than the substandard value.
                    if (currentTraitValue < substandardValue) {
                        revert InvalidRequiredValue(currentTraitValue, substandardValue);
                    }

                    // Decrement the trait by the trait value.
                    _setTrait(
                        traitRedemptions[i].traitKey,
                        traitRedemptions[i].identifier,
                        currentTraitValue - traitRedemptions[i].traitValue
                    );
                }
            }
        }

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

            // Transfer the token to the consideration recipient.
            ERC721(consideration[i].token).safeTransferFrom(owner, considerationRecipient, identifier);

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
    {}

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
    {}

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    function _isInactive(uint256 startTime, uint256 endTime) internal view returns (bool inactive) {
        // Using the same check for time boundary from Seaport.
        // startTime <= block.timestamp < endTime
        assembly {
            inactive := or(iszero(gt(endTime, timestamp())), gt(startTime, timestamp()))
        }
    }
}
