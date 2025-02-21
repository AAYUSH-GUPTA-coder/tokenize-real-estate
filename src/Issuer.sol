// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RealEstateToken} from "./RealEstateToken.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {FunctionsSource} from "./FunctionsSource.sol";

/**
 * @title Issuer
 * @dev Contract responsible for issuing fractionalized real estate NFTs.
 *      - Uses Chainlink Functions to fetch NFT metadata off-chain.
 *      - Ensures that only one issuance request can be processed at a time.
 *      - Integrates with the RealEstateToken contract for minting.
 */
contract Issuer is FunctionsClient, FunctionsSource, OwnerIsCreator {
    using FunctionsRequest for FunctionsRequest.Request;

    // Custom error indicating that an issuance request is already in progress
    error LatestIssueInProgress();

    /**
     * @dev Struct representing fractionalized NFT issuance details.
     * @param to The recipient address for the NFT.
     * @param amount The number of fractions (tokens) to issue.
     */
    struct FractionalizedNft {
        address to;
        uint256 amount;
    }

    // Immutable reference to the RealEstateToken contract
    RealEstateToken internal immutable i_realEstateToken;

    // Stores the last Chainlink Functions request ID for issuance tracking
    bytes32 internal s_lastRequestId;

    // Token ID counter for minting unique NFTs
    uint256 private s_nextTokenId;

    // Mapping to track ongoing issuance requests by request ID
    mapping(bytes32 requestId => FractionalizedNft) internal s_issuesInProgress;

    /**
     * @dev Constructor initializes the Issuer contract.
     * @param realEstateToken Address of the deployed RealEstateToken contract.
     * @param functionsRouterAddress Address of the Chainlink Functions router.
     */
    constructor(address realEstateToken, address functionsRouterAddress) FunctionsClient(functionsRouterAddress) {
        i_realEstateToken = RealEstateToken(realEstateToken);
    }

    /**
     * @notice Initiates the issuance of fractionalized NFTs.
     * @dev Sends a Chainlink Functions request to fetch NFT metadata and mints the NFT upon fulfillment.
     * @param to The address to receive the NFT.
     * @param amount The number of fractional tokens to mint.
     * @param subscriptionId Chainlink Functions subscription ID.
     * @param gasLimit The gas limit for the fulfillment callback.
     * @param donID The identifier for the Decentralized Oracle Network (DON).
     * @return requestId The ID of the Chainlink Functions request.
     */
    function issue(address to, uint256 amount, uint64 subscriptionId, uint32 gasLimit, bytes32 donID)
        external
        onlyOwner
        returns (bytes32 requestId)
    {
        // Revert if there is already a pending issuance request
        if (s_lastRequestId != bytes32(0)) revert LatestIssueInProgress();

        // Create and initialize a new Chainlink Functions request
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(this.getNftMetadata()); // Initialize the request with JS code

        // Encode the request and send it via Chainlink Functions
        requestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);

        // Store the request details for later fulfillment
        s_issuesInProgress[requestId] = FractionalizedNft(to, amount);
        s_lastRequestId = requestId;
    }

    /**
     * @notice Cancels the pending issuance request, if any.
     * @dev Only callable by the contract owner.
     */
    function cancelPendingRequest() external onlyOwner {
        s_lastRequestId = bytes32(0);
    }

    /**
     * @dev Callback function invoked by Chainlink Functions with the requested data.
     * @param requestId The ID of the Chainlink request being fulfilled.
     * @param response Encoded NFT metadata (token URI).
     * @param err Encoded error message, if any occurred during the off-chain computation.
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        // Revert if there was an error in the off-chain computation
        if (err.length != 0) {
            revert(string(err));
        }

        // Proceed only if the request matches the last pending issuance
        if (s_lastRequestId == requestId) {
            // Decode the token URI from the response
            string memory tokenURI = string(response);

            // Generate a new token ID and retrieve issuance details
            uint256 tokenId = s_nextTokenId++;
            FractionalizedNft memory fractionalizedNft = s_issuesInProgress[requestId];

            // Mint the fractionalized NFT via the RealEstateToken contract
            i_realEstateToken.mint(fractionalizedNft.to, tokenId, fractionalizedNft.amount, "", tokenURI);

            // Clear the pending request ID to allow new issuances
            s_lastRequestId = bytes32(0);
        }
    }
}
