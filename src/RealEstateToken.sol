// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Importing the contract that handles cross-chain minting and burning of ERC1155 tokens
import {CrossChainBurnAndMintERC1155} from "./CrossChainBurnAndMintERC1155.sol";
// Importing the contract that manages real estate price details via Chainlink Functions
import {RealEstatePriceDetails} from "./RealEstatePriceDetails.sol";

/**
 * @title RealEstateToken
 * @dev This contract represents a real estate token system that:
 *      - Inherits cross-chain mint and burn functionality from CrossChainBurnAndMintERC1155.
 *      - Incorporates real estate price details management from RealEstatePriceDetails.
 *
 *      It integrates Chainlink CCIP for cross-chain interactions and Chainlink Functions
 *      for fetching real estate price data. The constructor initializes both inherited contracts
 *      with the necessary parameters.
 */
contract RealEstateToken is CrossChainBurnAndMintERC1155, RealEstatePriceDetails {
    /**
     * @dev Constructor that initializes the RealEstateToken contract by passing the required
     *      parameters to the parent contracts CrossChainBurnAndMintERC1155 and RealEstatePriceDetails.
     *
     * @param uri_ The base URI for the ERC1155 token metadata.
     * @param ccipRouterAddress The address of the Chainlink CCIP router for cross-chain messaging.
     * @param linkTokenAddress The address of the LINK token contract used for fee payments.
     * @param currentChainSelector The unique identifier (selector) for the current blockchain network.
     * @param functionsRouterAddress The address of the Chainlink Functions router for off-chain data retrieval.
     */
    constructor(
        string memory uri_,
        address ccipRouterAddress,
        address linkTokenAddress,
        uint64 currentChainSelector,
        address functionsRouterAddress
    )
        // Initializing the CrossChainBurnAndMintERC1155 parent contract with its required parameters
        CrossChainBurnAndMintERC1155(uri_, ccipRouterAddress, linkTokenAddress, currentChainSelector)
        // Initializing the RealEstatePriceDetails parent contract with the Chainlink Functions router address
        RealEstatePriceDetails(functionsRouterAddress)
    {}
}