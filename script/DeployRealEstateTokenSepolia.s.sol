// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RealEstateToken} from "../src/RealEstateToken.sol";

/**
 * @title DeployRealEstateTokenSepolia
 * @dev Foundry deployment script for the RealEstateToken smart contract.
 *      This script uses Foundry's scripting capabilities to deploy the contract
 *      with the necessary parameters for cross-chain interaction and price details retrieval.
 */
contract DeployRealEstateTokenSepolia is Script {
    // Define constructor parameters
    string public constant BASE_URI = ""; // this is the base ERC-1155 token URI, we will leave it empty
    address public constant CCIP_ROUTER_ADDRESS = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59; // Ethereum Sepolia
    address public constant LINK_TOKEN_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789; // Ethereum Sepolia
    uint64 public constant CURRENT_CHAIN_SELECTOR = 16015286601757825753; // Ethereum Sepolia
    address public constant FUNCTIONS_ROUTER_ADDRESS = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0; // Ethereum Sepolia

    function run() external {
        // Start broadcasting transactions to the blockchain
        vm.startBroadcast();

        // Deploy the RealEstateToken contract with the required constructor arguments
        RealEstateToken realEstateToken = new RealEstateToken(
            BASE_URI, CCIP_ROUTER_ADDRESS, LINK_TOKEN_ADDRESS, CURRENT_CHAIN_SELECTOR, FUNCTIONS_ROUTER_ADDRESS
        );

        // Output the address of the deployed contract
        console2.log("RealEstateToken deployed on Ethereum Sepolia at:", address(realEstateToken));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/DeployRealEstateTokenSepolia.s.sol:DeployRealEstateTokenSepolia --account defaultKey --sender $WALLET_ADDRESS --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vv