// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RealEstateToken} from "../RealEstateToken.sol";
import {IERC1155Receiver, IERC165} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title RwaLending
 * @dev Contract enabling lending using Real Estate-backed ERC1155 tokens as collateral.
 *      Integrates Chainlink price feeds for real-time USDC valuation.
 *      Provides borrowing, repayment, and liquidation functionalities.
 */
contract RwaLending is IERC1155Receiver, OwnerIsCreator, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Struct to represent active loan details.
     * @param erc1155AmountSupplied Amount of ERC1155 tokens supplied as collateral.
     * @param usdcAmountLoaned Amount of USDC loaned against collateral.
     * @param usdcLiquidationThreshold Threshold value for loan liquidation.
     */
    struct LoanDetails {
        uint256 erc1155AmountSupplied;
        uint256 usdcAmountLoaned;
        uint256 usdcLiquidationThreshold;
    }

    // Immutable variables initialized during deployment
    RealEstateToken internal immutable i_realEstateToken;
    address internal immutable i_usdc;
    AggregatorV3Interface internal s_usdcUsdAggregator;
    uint32 internal s_usdcUsdFeedHeartbeat;

    uint256 internal immutable i_weightListPrice;
    uint256 internal immutable i_weightOriginalListPrice;
    uint256 internal immutable i_weightTaxAssessedValue;
    uint256 internal immutable i_ltvInitialThreshold;
    uint256 internal immutable i_ltvLiquidationThreshold;

    // Mapping for active loans: tokenId => borrower => LoanDetails
    mapping(uint256 tokenId => mapping(address borrower => LoanDetails)) internal s_activeLoans;

    // Events to track key activities
    event Borrow(
        uint256 indexed tokenId, uint256 amount, uint256 indexed loanAmount, uint256 indexed liquidationThreshold
    );
    event BorrowRepayed(uint256 indexed tokenId, uint256 indexed amount);
    event Liquidated(uint256 indexed tokenId);

    // Custom errors for gas-optimized reverts
    error AlreadyBorrowed(address borrower, uint256 tokenId);
    error OnlyRealEstateTokenSupported();
    error InvalidValuation();
    error SlippageToleranceExceeded();
    error PriceFeedDdosed();
    error InvalidRoundId();
    error StalePriceFeed();
    error NothingToRepay();

    /**
     * @dev Contract constructor initializes parameters and configurations.
     * @param realEstateTokenAddress address of the RealEstateToken contract
     * @param usdc addres of the USDC token
     * @param usdcUsdAggregatorAddress address of the chainlink price feed for USDC/USD
     * @param usdcUsdFeedHeartbeat time interval after which chainlink price feed value will change
     */
    constructor(
        address realEstateTokenAddress,
        address usdc,
        address usdcUsdAggregatorAddress,
        uint32 usdcUsdFeedHeartbeat
    ) {
        i_realEstateToken = RealEstateToken(realEstateTokenAddress);
        i_usdc = usdc;
        s_usdcUsdAggregator = AggregatorV3Interface(usdcUsdAggregatorAddress);
        s_usdcUsdFeedHeartbeat = usdcUsdFeedHeartbeat;

        i_weightListPrice = 50;
        i_weightOriginalListPrice = 30;
        i_weightTaxAssessedValue = 20;

        i_ltvInitialThreshold = 60;
        i_ltvLiquidationThreshold = 75;
    }

    /**
     * @notice Borrow USDC against ERC1155 real estate tokens.
     * @param tokenId Token ID of the ERC1155 asset.
     * @param amount Amount of tokens supplied as collateral.
     * @param data Extra data sent during safeTransferFrom.
     * @param minLoanAmount Minimum acceptable loan amount.
     * @param maxLiquidationThreshold Maximum acceptable liquidation threshold.
     */
    function borrow(
        uint256 tokenId,
        uint256 amount,
        bytes memory data,
        uint256 minLoanAmount,
        uint256 maxLiquidationThreshold
    ) external nonReentrant {
        if (s_activeLoans[tokenId][msg.sender].usdcAmountLoaned != 0) revert AlreadyBorrowed(msg.sender, tokenId);

        // normalizedValuation is the USDC-equivalent value of the portion of real estate tokens. 
        // for example, if the real estate value is $1000 and total supply is 20, then the normalizedValuation of 5 token is $250 and value of of 1 token is $50
        uint256 normalizedValuation = getValuationInUsdc(tokenId) * amount / i_realEstateToken.totalSupply(tokenId);
        if (normalizedValuation == 0) revert InvalidValuation();

        uint256 loanAmount = (normalizedValuation * i_ltvInitialThreshold) / 100;
        if (loanAmount < minLoanAmount) revert SlippageToleranceExceeded();

        uint256 liquidationThreshold = (normalizedValuation * i_ltvLiquidationThreshold) / 100;
        if (liquidationThreshold > maxLiquidationThreshold) revert SlippageToleranceExceeded();

        i_realEstateToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, data);
        s_activeLoans[tokenId][msg.sender] = LoanDetails(amount, loanAmount, liquidationThreshold);
        IERC20(i_usdc).safeTransfer(msg.sender, loanAmount);

        emit Borrow(tokenId, amount, loanAmount, liquidationThreshold);
    }

    /**
     * @notice Repay a loan and retrieve the collateralized ERC1155 tokens.
     * @param tokenId Token ID linked to the loan.
     */
    function repay(uint256 tokenId) external nonReentrant {
        LoanDetails memory loanDetails = s_activeLoans[tokenId][msg.sender];
        if (loanDetails.usdcAmountLoaned == 0) revert NothingToRepay();

        delete s_activeLoans[tokenId][msg.sender];
        IERC20(i_usdc).safeTransferFrom(msg.sender, address(this), loanDetails.usdcAmountLoaned);
        i_realEstateToken.safeTransferFrom(address(this), msg.sender, tokenId, loanDetails.erc1155AmountSupplied, "");

        emit BorrowRepayed(tokenId, loanDetails.erc1155AmountSupplied);
    }

    /**
     * @notice Liquidate a loan when valuation drops below threshold.
     * @param tokenId Token ID of the collateralized asset.
     * @param borrower Address of the borrower to liquidate.
     */
    function liquidate(uint256 tokenId, address borrower) external {
        LoanDetails memory loanDetails = s_activeLoans[tokenId][borrower];

        uint256 normalizedValuation =
            getValuationInUsdc(tokenId) * loanDetails.erc1155AmountSupplied / i_realEstateToken.totalSupply(tokenId);
        if (normalizedValuation == 0) revert InvalidValuation();

        uint256 liquidationThreshold = (normalizedValuation * i_ltvLiquidationThreshold) / 100;
        if (liquidationThreshold < loanDetails.usdcLiquidationThreshold) {
            delete s_activeLoans[tokenId][borrower];
            emit Liquidated(tokenId);
        }
    }

    /**
     * @notice Retrieves USDC price in USD from Chainlink price feed.
     * @return Price of 1 USDC in USD (with proper decimals).
     */
    function getUsdcPriceInUsd() public view returns (uint256) {
        (uint80 roundId, int256 price,, uint256 updatedAt,) = s_usdcUsdAggregator.latestRoundData();
        if (roundId == 0) revert InvalidRoundId();
        if (updatedAt < block.timestamp - s_usdcUsdFeedHeartbeat) revert StalePriceFeed();

        return uint256(price);
    }

    /**
     * @notice Calculates the valuation of an ERC1155 token in USDC.
     * @param tokenId Token ID to evaluate.
     * @return Valuation of the token in USDC.
     */
    function getValuationInUsdc(uint256 tokenId) public view returns (uint256) {
        RealEstateToken.PriceDetails memory priceDetails = i_realEstateToken.getPriceDetails(tokenId);

        uint256 valuation = (
            i_weightListPrice * priceDetails.listPrice + i_weightOriginalListPrice * priceDetails.originalListPrice
                + i_weightTaxAssessedValue * priceDetails.taxAssessedValue
        ) / (i_weightListPrice + i_weightOriginalListPrice + i_weightTaxAssessedValue);

        uint256 usdcPriceInUsd = getUsdcPriceInUsd();
        uint256 normalizedValuation =
            Math.mulDiv(valuation * usdcPriceInUsd, 10 ** 6, 10 ** s_usdcUsdAggregator.decimals());

        return normalizedValuation;
    }

    /**
     * @notice Updates the USDC-USD price feed details.
     * @param usdcUsdAggregatorAddress New Chainlink aggregator address.
     * @param usdcUsdFeedHeartbeat New heartbeat value for price feed freshness.
     */
    function setUsdcUsdPriceFeedDetails(address usdcUsdAggregatorAddress, uint32 usdcUsdFeedHeartbeat)
        external
        onlyOwner
    {
        s_usdcUsdAggregator = AggregatorV3Interface(usdcUsdAggregatorAddress);
        s_usdcUsdFeedHeartbeat = usdcUsdFeedHeartbeat;
    }

    /**
     * @dev ERC1155Receiver interface implementation to accept ERC1155 tokens.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external view returns (bytes4) {
        if (msg.sender != address(i_realEstateToken)) revert OnlyRealEstateTokenSupported();
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        view
        returns (bytes4)
    {
        if (msg.sender != address(i_realEstateToken)) revert OnlyRealEstateTokenSupported();
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Declares support for IERC1155Receiver and IERC165 interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
