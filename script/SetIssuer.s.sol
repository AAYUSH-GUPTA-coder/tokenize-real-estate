// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RealEstateToken} from "../src/RealEstateToken.sol";

/**
 * @title SetIssuerScript
 * @dev Foundry script to call the `setIssuer` function on the RealEstateToken contract
 *      deployed on Avalanche Fuji. The script sets the Issuer contract address as the issuer.
 */
contract SetIssuerScript is Script {
    // Address of the deployed RealEstateToken contract (replace with actual address before running)
    address public constant REAL_ESTATE_TOKEN_ADDRESS = 0xb8c7e1f97C2D6C1893B1fEe7D0c42A9468761908;

    // Address of the deployed Issuer contract (replace with actual address before running)
    address public constant ISSUER_CONTRACT_ADDRESS = 0x1922968E9A8131FEda8bD04c1dD0312A78a0356C;

    /**
     * @dev Executes the setIssuer function on the RealEstateToken contract.
     */
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Create an instance of the RealEstateToken contract
        RealEstateToken realEstateToken = RealEstateToken(REAL_ESTATE_TOKEN_ADDRESS);

        // Call the setIssuer function with the Issuer contract address
        realEstateToken.setIssuer(ISSUER_CONTRACT_ADDRESS);

        // Log the result
        console2.log("setIssuer called successfully. Issuer set to:", ISSUER_CONTRACT_ADDRESS);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}


// forge script script/SetIssuer.s.sol:SetIssuerScript --account defaultKey --sender $WALLET_ADDRESS --rpc-url $FUJI_RPC_URL --broadcast -vv