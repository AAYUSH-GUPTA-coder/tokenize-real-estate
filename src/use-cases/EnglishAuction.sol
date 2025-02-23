// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver, IERC165} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title EnglishAuction
 * @dev Implements an English auction mechanism for fractionalized real estate ERC1155 tokens.
 *      The auction allows bids over 7 days, where the highest bidder wins at the end.
 */
contract EnglishAuction is IERC1155Receiver, ReentrancyGuard {
    error EnglishAuction_OnlySellerCanCall();
    error EnglishAuction_AuctionAlreadyStarted();
    error OnlyRealEstateTokenSupported();
    error EnglishAuction_NoAuctionsInProgress();
    error EnglishAuction_AuctionEnded();
    error EnglishAuction_BidNotHighEnough();
    error EnglishAuction_CannotWithdrawHighestBid();
    error EnglishAuction_TooEarlyToEnd();
    error FailedToWithdrawBid(address bidder, uint256 amount);
    error NothingToWithdraw();
    error FailedToSendEth(address recipient, uint256 amount);

    // Immutable variables for seller and ERC1155 token contract
    address internal immutable i_seller;
    address internal immutable i_fractionalizedRealEstateToken;

    // Auction state variables
    bool internal s_started;
    uint48 internal s_endTimestamp;
    address internal s_highestBidder;
    uint256 internal s_highestBid;
    uint256 internal s_tokenIdOnAuction;
    uint256 internal s_fractionalizedAmountOnAuction;

    // Mapping to track bids from each bidder
    mapping(address bidder => uint256 totalBiddedEth) internal s_bids;

    // Events for key auction lifecycle moments
    event AuctionStarted(uint256 indexed tokenId, uint256 indexed amount, uint48 indexed endTimestamp);
    event Bid(address indexed bidder, uint256 indexed amount);
    event AuctionEnded(uint256 indexed tokenId, uint256 amount, address indexed winner, uint256 indexed winningBid);

    /**
     * @dev Initializes the auction with the fractionalized token contract address.
     * @param fractionalizedRealEstateTokenAddress Address of the ERC1155 token contract.
     */
    constructor(address fractionalizedRealEstateTokenAddress) {
        i_seller = msg.sender;
        i_fractionalizedRealEstateToken = fractionalizedRealEstateTokenAddress;
    }

    /**
     * @notice Starts the auction by transferring tokens from the seller to this contract.
     * @param tokenId Token ID of the real estate asset.
     * @param amount Amount of tokens to be auctioned.
     * @param data Additional data (if any) for ERC1155 transfer.
     * @param startingBid Minimum bid amount to start the auction.
     */
    function startAuction(uint256 tokenId, uint256 amount, bytes calldata data, uint256 startingBid)
        external
        nonReentrant
    {
        if (s_started) revert EnglishAuction_AuctionAlreadyStarted();
        if (msg.sender != i_seller) revert EnglishAuction_OnlySellerCanCall();

        IERC1155(i_fractionalizedRealEstateToken).safeTransferFrom(i_seller, address(this), tokenId, amount, data);

        s_started = true;
        s_endTimestamp = SafeCast.toUint48(block.timestamp + 7 days);
        s_tokenIdOnAuction = tokenId;
        s_fractionalizedAmountOnAuction = amount;
        s_highestBidder = msg.sender;
        s_highestBid = startingBid;

        emit AuctionStarted(tokenId, amount, s_endTimestamp);
    }

    /**
     * @notice Allows users to bid on the auction. Must be higher than the current highest bid.
     */
    function bid() external payable nonReentrant {
        if (!s_started) revert EnglishAuction_NoAuctionsInProgress();
        if (block.timestamp >= s_endTimestamp) revert EnglishAuction_AuctionEnded();
        if (msg.value <= s_highestBid) revert EnglishAuction_BidNotHighEnough();

        s_highestBidder = msg.sender;
        s_highestBid = msg.value;
        s_bids[msg.sender] += msg.value;

        emit Bid(msg.sender, msg.value);
    }

    /**
     * @notice Allows bidders (except the highest) to withdraw their bids.
     */
    function withdrawBid() external nonReentrant {
        if (msg.sender == s_highestBidder) revert EnglishAuction_CannotWithdrawHighestBid();

        uint256 amount = s_bids[msg.sender];
        if (amount == 0) revert NothingToWithdraw();
        delete s_bids[msg.sender];

        (bool sent,) = msg.sender.call{value: amount}("");
        if (!sent) revert FailedToWithdrawBid(msg.sender, amount);
    }

    /**
     * @notice Ends the auction, transfers the asset to the winner, and funds to the seller.
     */
    function endAuction() external nonReentrant {
        if (!s_started) revert EnglishAuction_NoAuctionsInProgress();
        if (block.timestamp < s_endTimestamp) revert EnglishAuction_TooEarlyToEnd();

        s_started = false;

        IERC1155(i_fractionalizedRealEstateToken).safeTransferFrom(
            address(this), s_highestBidder, s_tokenIdOnAuction, s_fractionalizedAmountOnAuction, ""
        );

        (bool sent,) = i_seller.call{value: s_highestBid}("");
        if (!sent) revert FailedToSendEth(i_seller, s_highestBid);

        emit AuctionEnded(s_tokenIdOnAuction, s_fractionalizedAmountOnAuction, s_highestBidder, s_highestBid);
    }

    /**
     * @dev Handles single ERC1155 token transfers. Reverts if the token is unsupported.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external view returns (bytes4) {
        if (msg.sender != address(i_fractionalizedRealEstateToken)) revert OnlyRealEstateTokenSupported();
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @dev Handles batch ERC1155 token transfers. Reverts if tokens are unsupported.
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        view
        returns (bytes4)
    {
        if (msg.sender != address(i_fractionalizedRealEstateToken)) revert OnlyRealEstateTokenSupported();
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /**
     * @notice Declares support for ERC1155Receiver and ERC165 interfaces.
     * @param interfaceId The interface identifier.
     * @return True if interface is supported.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
