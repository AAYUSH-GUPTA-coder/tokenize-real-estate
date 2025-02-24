// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RealEstateToken} from "../src/RealEstateToken.sol";

/**
 * @title DeployRealEstateTokenArbSepolia
 * @dev Foundry deployment script for the RealEstateToken smart contract.
 *      This script uses Foundry's scripting capabilities to deploy the contract
 *      with the necessary parameters for cross-chain interaction and price details retrieval.
 */
contract DeployRealEstateTokenArbSepolia is Script {
    // Define constructor parameters
    string public constant BASE_URI = ""; // this is the base ERC-1155 token URI, we will leave it empty
    address public constant CCIP_ROUTER_ADDRESS = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165; // Arb Sepolia
    address public constant LINK_TOKEN_ADDRESS = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E; // Arb Sepolia
    uint64 public constant CURRENT_CHAIN_SELECTOR = 3478487238524512106; // Arb Sepolia
    address public constant FUNCTIONS_ROUTER_ADDRESS = 0x234a5fb5Bd614a7AA2FfAB244D603abFA0Ac5C5C; // Arb Sepolia

    function run() external {
        // Start broadcasting transactions to the blockchain
        vm.startBroadcast();

        // Deploy the RealEstateToken contract with the required constructor arguments
        RealEstateToken realEstateToken = new RealEstateToken(
            BASE_URI, CCIP_ROUTER_ADDRESS, LINK_TOKEN_ADDRESS, CURRENT_CHAIN_SELECTOR, FUNCTIONS_ROUTER_ADDRESS
        );

        // Output the address of the deployed contract
        console2.log("RealEstateToken deployed on Arb Sepolia at:", address(realEstateToken));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/DeployRealEstateTokenArbSepolia.s.sol:DeployRealEstateTokenArbSepolia --account defaultKey --sender $WALLET_ADDRESS --rpc-url $ARB_SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vv
