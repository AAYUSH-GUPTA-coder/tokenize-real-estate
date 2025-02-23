// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Issuer} from "../src/Issuer.sol";

/**
 * @title CallCancelPendingRequest
 * @dev Foundry script to call the `CallCancelPendingRequest` function on the Issuer contract deployed on Avalanche Fuji.
 */
contract CallCancelPendingRequest is Script {
    // Address of the deployed Issuer contract (replace with actual address before running)
    address public constant ISSUER_CONTRACT_ADDRESS = 0x1922968E9A8131FEda8bD04c1dD0312A78a0356C;

    /**
     * @dev Executes the `cancelPendingRequest` function on the Issuer contract.
     */
    function run() external {
        // Start broadcasting transactions from the deployer's address
        vm.startBroadcast();

        // Create an instance of the Issuer contract
        Issuer issuer = Issuer(ISSUER_CONTRACT_ADDRESS);

        // Call the cancelPendingRequest
        issuer.cancelPendingRequest();

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/CallCancelPendingRequest.s.sol:CallCancelPendingRequest --account defaultKey --sender $WALLET_ADDRESS --rpc-url $FUJI_RPC_URL --broadcast -vv
