// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RealEstateToken} from "../src/RealEstateToken.sol";

/**
 * @title EnableChainScript
 * @dev Foundry script to call the `enableChain` function on the CrossChainBurnAndMintERC1155 contract.
 *      This script enables a specified destination chain for cross-chain operations.
 */
contract EnableChainScriptSepolia is Script {
    // Chain selector for the destination chain
    uint64 public constant DEST_CHAIN_SELECTOR = 14767482510784806043; // ChainID of Avalanche Fuji

    address public constant REAL_ESTATE_TOKEN_ADDRESS = 0x887a5Dd013F5A8a568e9AF4F73E6f8F069057953; // Address of the RealEstateToken contract on the Ethereum Sepolia chain

    // Address of the cross-chain NFT contract on the destination chain. Actually it is the address of RealEstateToken contract
    address public constant XNFT_ADDRESS = 0xb8c7e1f97C2D6C1893B1fEe7D0c42A9468761908; // Address of the XNFT_ADDRESS / RealEstateToken on the Avalanche Fuji chain

    // Extra arguments for CCIP
    bytes public constant CCIP_EXTRA_ARGS = ""; // intentially putting the value to zero

    /**
     * @dev Executes the `enableChain` function on the CrossChainBurnAndMintERC1155 contract.
     */
    function run() external {
        // Start broadcasting transactions from the deployer's address
        vm.startBroadcast();

        // Create an instance of the RealEstateToken contract
        RealEstateToken realEstateToken = RealEstateToken(REAL_ESTATE_TOKEN_ADDRESS);

        // Call the enableChain function with the specified parameters
        realEstateToken.enableChain(DEST_CHAIN_SELECTOR, XNFT_ADDRESS, CCIP_EXTRA_ARGS);

        // Log confirmation
        console2.log("enableChain called successfully for chain selector:", DEST_CHAIN_SELECTOR);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// forge script script/EnableChainScriptSepolia.s.sol:EnableChainScriptSepolia --account defaultKey --sender $WALLET_ADDRESS --rpc-url $SEPOLIA_RPC_URL --broadcast -vv
