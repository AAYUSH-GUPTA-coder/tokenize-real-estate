// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Importing access control contract where the owner is set as the creator
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
// Importing Chainlink FunctionsClient for off-chain computation requests
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
// Importing library to structure and encode function requests
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
// Importing a custom contract that provides the JavaScript source for price retrieval
import {FunctionsSource} from "./FunctionsSource.sol";

/**
 * @title RealEstatePriceDetails
 * @dev An example contract to retrieve and store real estate price details using Chainlink Functions.
 */
contract RealEstatePriceDetails is FunctionsClient, FunctionsSource, OwnerIsCreator {
    // Apply FunctionsRequest library methods to FunctionsRequest.Request type
    using FunctionsRequest for FunctionsRequest.Request;

    /**
     * @dev Struct to store price details for real estate tokens.
     */
    struct PriceDetails {
        uint80 listPrice;
        uint80 originalListPrice;
        uint80 taxAssessedValue;
    }

    // Address authorized to forward automation requests
    address internal s_automationForwarderAddress;

    // Mapping to store price details for each token ID
    mapping(uint256 tokenId => PriceDetails) internal s_priceDetails;

    // Custom error for unauthorized access
    error OnlyAutomationForwarderOrOwnerCanCall();

    /**
     * @dev Modifier to allow access only to the automation forwarder or the contract owner.
     */
    modifier onlyAutomationForwarderOrOwner() {
        if (msg.sender != s_automationForwarderAddress && msg.sender != owner()) {
            revert OnlyAutomationForwarderOrOwnerCanCall();
        }
        _;
    }

    /**
     * @dev Constructor sets the Chainlink Functions router address.
     * @param functionsRouterAddress Address of the Chainlink Functions router.
     */
    constructor(address functionsRouterAddress) FunctionsClient(functionsRouterAddress) {}

    /**
     * @notice Sets the address authorized to forward automation requests.
     * @dev Only callable by the owner.
     * @param automationForwarderAddress Address of the automation forwarder.
     */
    function setAutomationForwarder(address automationForwarderAddress) external onlyOwner {
        s_automationForwarderAddress = automationForwarderAddress;
    }

    /**
     * @notice Initiates a request to update real estate price details.
     * @dev Calls Chainlink Functions with JavaScript logic provided by FunctionsSource.
     * @param tokenId ID of the real estate token (string format for JS processing).
     * @param subscriptionId Chainlink Functions subscription ID.
     * @param gasLimit Maximum gas allowed for the callback.
     * @param donID Decentralized Oracle Network identifier.
     * @return requestId The unique identifier for the request.
     */
    function updatePriceDetails(string memory tokenId, uint64 subscriptionId, uint32 gasLimit, bytes32 donID)
        external
        onlyAutomationForwarderOrOwner
        returns (bytes32 requestId)
    {
        // Create a new request instance
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(this.getPrices()); // Initialize the request with JS code
        // FunctionsRequest.initializeRequestForInlineJavaScript(req, this.getPrices()); // Initialize the request with JS code

        // Setting the tokenId as an argument for the JS function
        string[] memory args = new string[](1);
        args[0] = tokenId;
        req.setArgs(args);

        // Encode request and send to Chainlink Functions
        requestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);
    }

    /**
     * @notice Retrieves price details for a given token ID.
     * @param tokenId The ID of the token.
     * @return PriceDetails struct containing list price, original list price, and tax assessed value.
     */
    function getPriceDetails(uint256 tokenId) external view returns (PriceDetails memory) {
        return s_priceDetails[tokenId];
    }

    /**
     * @dev Callback function that handles the response from Chainlink Functions.
     * @param requestId The ID of the request (ignored in this implementation).
     * @param response Encoded response data from Chainlink Functions.
     * @param err Encoded error message, if any.
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        // If error data exists, revert with the error message
        if (err.length != 0) {
            revert(string(err));
        }

        // Decode the response data and store it in the mapping
        (uint256 tokenId, uint256 listPrice, uint256 originalListPrice, uint256 taxAssessedValue) =
            abi.decode(response, (uint256, uint256, uint256, uint256));

        s_priceDetails[tokenId] = PriceDetails({
            listPrice: uint80(listPrice),
            originalListPrice: uint80(originalListPrice),
            taxAssessedValue: uint80(taxAssessedValue)
        });
    }
}
