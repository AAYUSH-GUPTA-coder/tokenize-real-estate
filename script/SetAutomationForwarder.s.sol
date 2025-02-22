// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RealEstatePriceDetails} from "../src/RealEstatePriceDetails.sol";

/**
 * @title SetAutomationForwarder
 * @dev Foundry script to call the `setAutomationForwarder` function on the RealEstatePriceDetails contract.
 *      This script sets the automation forwarder address required for automated interactions.
 */
contract SetAutomationForwarder is Script {
    // Address of the deployed RealEstatePriceDetails contract
    address public constant REAL_ESTATE_PRICE_DETAILS_ADDRESS = 0xb8c7e1f97C2D6C1893B1fEe7D0c42A9468761908;

    // Address of the automation forwarder
    address public constant AUTOMATION_FORWARDER_ADDRESS = 0x363F605102b11a792052554D386DDD69bD6b6f2b;

    /**
     * @dev Executes the `setAutomationForwarder` function on the RealEstatePriceDetails contract.
     */
    function run() external {
        // Start broadcasting transactions from the deployer's address
        vm.startBroadcast();

        // Create an instance of the RealEstatePriceDetails contract
        RealEstatePriceDetails realEstatePriceDetails = RealEstatePriceDetails(REAL_ESTATE_PRICE_DETAILS_ADDRESS);

        // Call the setAutomationForwarder function with the specified address
        realEstatePriceDetails.setAutomationForwarder(AUTOMATION_FORWARDER_ADDRESS);

        // Log confirmation
        console2.log("setAutomationForwarder called successfully. Forwarder set to:", AUTOMATION_FORWARDER_ADDRESS);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/SetAutomationForwarder.s.sol:SetAutomationForwarder --account defaultKey --sender $WALLET_ADDRESS --rpc-url $FUJI_RPC_URL --broadcast -vv