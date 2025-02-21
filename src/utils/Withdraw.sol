// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";

/**
 * @title Withdraw
 * @dev Contract that allows the owner (deployer) to withdraw Ether and ERC20 tokens.
 *      Uses SafeERC20 for secure token transfers and custom errors for better gas efficiency.
 */
contract Withdraw is OwnerIsCreator {
    // Applying SafeERC20 library functions to the IERC20 type
    using SafeERC20 for IERC20;

    // Custom error when there's no Ether or tokens to withdraw
    error NothingToWithdraw();

    // Custom error for failed Ether withdrawal attempts
    error FailedToWithdrawEth(address owner, address target, uint256 value);

    /**
     * @notice Withdraws all Ether from the contract to the specified beneficiary.
     * @dev Only the contract owner can call this function.
     * @param _beneficiary The address that will receive the withdrawn Ether.
     */
    function withdraw(address _beneficiary) public onlyOwner {
        uint256 amount = address(this).balance; // Get contract's Ether balance

        // Revert if there is no Ether to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to transfer Ether to the beneficiary
        (bool sent,) = _beneficiary.call{value: amount}("");

        // Revert if the Ether transfer fails
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    /**
     * @notice Withdraws all ERC20 tokens of a specified type from the contract to a beneficiary.
     * @dev Only the contract owner can call this function. Uses SafeERC20 for safe transfers.
     * @param _beneficiary The address that will receive the withdrawn tokens.
     * @param _token The address of the ERC20 token contract.
     */
    function withdrawToken(address _beneficiary, address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this)); // Get contract's token balance

        // Revert if there are no tokens to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Safely transfer all tokens to the beneficiary
        IERC20(_token).safeTransfer(_beneficiary, amount);
    }
}
