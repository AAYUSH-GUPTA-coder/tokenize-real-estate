// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {EnglishAuction} from "../src/use-cases/EnglishAuction.sol";

/**
 * @title DeployEnglishAuction
 * @dev Foundry deployment script for the EnglishAuction smart contract.
 *      This script deploys the EnglishAuction contract with the specified
 *      fractionalized real estate token address.
 */
contract DeployEnglishAuction is Script {
    // Address of the fractionalized real estate ERC1155 token (update before running)
    address public constant FRACTIONALIZED_REAL_ESTATE_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000000; // <-- Update this address

    /**
     * @dev Executes the deployment of the EnglishAuction contract.
     */
    function run() external {
        // Start broadcasting transactions to the network
        vm.startBroadcast();

        // Deploy the EnglishAuction contract
        EnglishAuction englishAuction = new EnglishAuction(FRACTIONALIZED_REAL_ESTATE_TOKEN_ADDRESS);

        // Log the deployed contract address
        console2.log("EnglishAuction contract deployed at:", address(englishAuction));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/DeployEnglishAuction.s.sol:DeployEnglishAuction --account defaultKey --sender $WALLET_ADDRESS --rpc-url $FUJI_RPC_URL --broadcast -vv