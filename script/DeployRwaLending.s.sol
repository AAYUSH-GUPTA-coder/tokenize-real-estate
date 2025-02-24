// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RwaLending} from "../src/use-cases/RwaLending.sol";

/**
 * @title DeployRwaLending
 * @dev Foundry deployment script for the RwaLending smart contract.
 *      This script deploys the RwaLending contract with specified parameters
 *      including RealEstateToken address, USDC address, Chainlink aggregator address,
 *      and heartbeat for the price feed.
 */
contract DeployRwaLending is Script {
    // Address of the deployed RealEstateToken contract 
    address public constant REAL_ESTATE_TOKEN_ADDRESS = 0xb8c7e1f97C2D6C1893B1fEe7D0c42A9468761908; 

    // Address of the USDC token on the network
    address public constant USDC_ADDRESS = 0x5425890298aed601595a70AB815c96711a31Bc65;

    // Address of the Chainlink USDC/USD price feed aggregator
    address public constant USDC_USD_AGGREGATOR_ADDRESS = 0x97FE42a7E96640D932bbc0e1580c73E705A8EB73;

    // Heartbeat interval for the price feed (24 hours = 86400 seconds)
    uint32 public constant USDC_USD_FEED_HEARTBEAT = 86400;

    /**
     * @dev Executes the deployment of the RwaLending contract.
     */
    function run() external {
        // Start broadcasting transactions from the deployer's address
        vm.startBroadcast();

        // Deploy the RwaLending contract with the specified parameters
        RwaLending rwaLending = new RwaLending(
            REAL_ESTATE_TOKEN_ADDRESS, USDC_ADDRESS, USDC_USD_AGGREGATOR_ADDRESS, USDC_USD_FEED_HEARTBEAT
        );

        // Output the address of the deployed contract
        console2.log("RwaLending contract deployed at:", address(rwaLending));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/DeployRwaLending.s.sol:DeployRwaLending --account defaultKey --sender $WALLET_ADDRESS --rpc-url $FUJI_RPC_URL --broadcast -vv