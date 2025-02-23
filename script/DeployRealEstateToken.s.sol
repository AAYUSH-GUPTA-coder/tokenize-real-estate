// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RealEstateToken} from "../src/RealEstateToken.sol";

/**
 * @title DeployRealEstateToken
 * @dev Foundry deployment script for the RealEstateToken smart contract.
 *      This script uses Foundry's scripting capabilities to deploy the contract
 *      with the necessary parameters for cross-chain interaction and price details retrieval.
 */
contract DeployRealEstateToken is Script {
    // Define constructor parameters
    string public constant BASE_URI = ""; // this is the base ERC-1155 token URI, we will leave it empty
    address public constant CCIP_ROUTER_ADDRESS = 0xF694E193200268f9a4868e4Aa017A0118C9a8177; // Avalanche Fuji
    address public constant LINK_TOKEN_ADDRESS = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846; // Avalanche Fuji
    uint64 public constant CURRENT_CHAIN_SELECTOR = 14767482510784806043; // Avalanche Fuji
    address public constant FUNCTIONS_ROUTER_ADDRESS = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0; // Avalanche Fuji

    function run() external {
        // Start broadcasting transactions to the blockchain
        vm.startBroadcast();

        // Deploy the RealEstateToken contract with the required constructor arguments
        RealEstateToken realEstateToken = new RealEstateToken(
            BASE_URI, CCIP_ROUTER_ADDRESS, LINK_TOKEN_ADDRESS, CURRENT_CHAIN_SELECTOR, FUNCTIONS_ROUTER_ADDRESS
        );

        // Output the address of the deployed contract
        console2.log("RealEstateToken deployed on Avalanche Fuji at:", address(realEstateToken));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}


// forge script script/DeployRealEstateToken.s.sol:DeployRealEstateToken --account defaultKey --sender $WALLET_ADDRESS --rpc-url $FUJI_RPC_URL --broadcast -vv