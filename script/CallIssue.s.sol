// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Issuer} from "../src/Issuer.sol";

/**
 * @title CallIssue
 * @dev Foundry script to call the `issue` function on the Issuer contract deployed on Avalanche Fuji.
 *      The script issues an ERC-1155 token to a specified address with provided Chainlink Functions parameters.
 */
contract CallIssue is Script {
    // Address of the deployed Issuer contract
    address public constant ISSUER_CONTRACT_ADDRESS = 0x1922968E9A8131FEda8bD04c1dD0312A78a0356C; 

    // Address of Alice / any address you own
    address public constant ALICE_ADDRESS = 0xdbea613E2bBD96d84c75f1856E088e8429E1Be72; // Account 1 address

    // Chainlink Functions parameters
    uint256 public constant AMOUNT = 20;
    uint64 public constant SUBSCRIPTION_ID = 15379; // Chainlink Functions Subscription ID
    uint32 public constant GAS_LIMIT = 300000;
    bytes32 public constant DON_ID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000; // fun-avalanche-fuji-1

    /**
     * @dev Executes the `issue` function on the Issuer contract.
     */
    function run() external {
        // Start broadcasting transactions from the deployer's address
        vm.startBroadcast();

        // Create an instance of the Issuer contract
        Issuer issuer = Issuer(ISSUER_CONTRACT_ADDRESS);

        // Call the issue function with the specified parameters
        bytes32 requestId = issuer.issue(ALICE_ADDRESS, AMOUNT, SUBSCRIPTION_ID, GAS_LIMIT, DON_ID);

        // Log the request ID for tracking purposes
        console2.log("Issue function called successfully. Request ID:");
        console2.logBytes32(requestId);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/CallIssue.s.sol:CallIssue --account defaultKey --sender $WALLET_ADDRESS --rpc-url $FUJI_RPC_URL --broadcast -vv