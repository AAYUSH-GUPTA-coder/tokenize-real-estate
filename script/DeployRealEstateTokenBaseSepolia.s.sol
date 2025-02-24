// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RealEstateToken} from "../src/RealEstateToken.sol";

/**
 * @title DeployRealEstateTokenBaseSepolia
 * @dev Foundry deployment script for the RealEstateToken smart contract.
 *      This script uses Foundry's scripting capabilities to deploy the contract
 *      with the necessary parameters for cross-chain interaction and price details retrieval.
 */
contract DeployRealEstateTokenBaseSepolia is Script {
    // Define constructor parameters
    string public constant BASE_URI = ""; // this is the base ERC-1155 token URI, we will leave it empty
    address public constant CCIP_ROUTER_ADDRESS = 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93; // Base Sepolia
    address public constant LINK_TOKEN_ADDRESS = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410; // Base Sepolia
    uint64 public constant CURRENT_CHAIN_SELECTOR = 10344971235874465080; // Base Sepolia
    address public constant FUNCTIONS_ROUTER_ADDRESS = 0xf9B8fc078197181C841c296C876945aaa425B278; // Base Sepolia

    function run() external {
        // Start broadcasting transactions to the blockchain
        vm.startBroadcast();

        // Deploy the RealEstateToken contract with the required constructor arguments
        RealEstateToken realEstateToken = new RealEstateToken(
            BASE_URI, CCIP_ROUTER_ADDRESS, LINK_TOKEN_ADDRESS, CURRENT_CHAIN_SELECTOR, FUNCTIONS_ROUTER_ADDRESS
        );

        // Output the address of the deployed contract
        console2.log("RealEstateToken deployed on Base Sepolia at:", address(realEstateToken));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/DeployRealEstateTokenBaseSepolia.s.sol:DeployRealEstateTokenBaseSepolia --account defaultKey --sender $WALLET_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vv
