// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Issuer} from "../src/Issuer.sol";

/**
 * @title DeployIssuer
 * @dev Foundry deployment script for the Issuer smart contract on Avalanche Fuji.
 *      The script requires the previously deployed RealEstateToken contract address
 *      and the Chainlink Functions router address for Fuji.
 */
contract DeployIssuer is Script {
    // Address of the deployed RealEstateToken contract (replace with actual address before running)
    address public constant REAL_ESTATE_TOKEN_ADDRESS = 0xb8c7e1f97C2D6C1893B1fEe7D0c42A9468761908; // Update the address of RealEstateToken contract

    // Chainlink Functions router address for Avalanche Fuji
    address public constant FUNCTIONS_ROUTER_ADDRESS = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;

    /**
     * @dev Deploys the Issuer contract using Foundry's vm scripting environment.
     */
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the Issuer contract with the required constructor arguments
        Issuer issuer = new Issuer(REAL_ESTATE_TOKEN_ADDRESS, FUNCTIONS_ROUTER_ADDRESS);

        // Output the deployed Issuer contract address
        console2.log("Issuer contract deployed at:", address(issuer));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}


// forge script script/DeployIssuer.s.sol:DeployIssuer --account defaultKey --sender $WALLET_ADDRESS --rpc-url $FUJI_RPC_URL --broadcast -vv