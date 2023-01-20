// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICollateralFilter.sol";
import "./IInterestRateModel.sol";
import "./ICollateralLiquidator.sol";
import "./INoteAdapter.sol";
import "./ILendAdapter.sol";

/**
 * @title Interface to a Pool
 */
interface IPool {
    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when currency is deposited
     * @param account Account
     * @param depth Loan limit depth
     * @param amount Amount of currency tokens
     * @param shares Amount of shares allocated
     */
    event Deposited(address indexed account, uint256 indexed depth, uint256 amount, uint256 shares);

    /**
     * @notice Emitted when deposit shares are redeemed
     * @param account Account
     * @param depth Loan limit depth
     * @param shares Amount of shares to be redeemed
     */
    event Redeemed(address indexed account, uint256 indexed depth, uint256 shares);

    /**
     * @notice Emitted when redeemed currency tokens are withdrawn
     * @param account Account
     * @param depth Loan limit depth
     * @param shares Amount of shares redeemed
     * @param amount Amount of currency tokens withdrawn
     */
    event Withdrawn(address indexed account, uint256 indexed depth, uint256 shares, uint256 amount);

    /**
     * @notice Emitted when a loan is purchased
     * @param loanId Loan ID
     * @param loanReceipt Loan receipt
     */
    event LoanPurchased(uint256 indexed loanId, bytes loanReceipt);

    /**
     * @notice Emitted when a loan is originated
     * @param loanId Loan ID
     * @param loanReceipt Loan receipt
     */
    event LoanOriginated(uint256 indexed loanId, bytes loanReceipt);

    /**
     * @notice Emitted when a loan is repaid
     * @param loanId Loan ID
     */
    event LoanRepaid(uint256 indexed loanId);

    /**
     * @notice Emitted when a loan is liquidated
     * @param loanId Loan ID
     */
    event LoanLiquidated(uint256 indexed loanId);

    /**
     * @notice Emitted when loan collateral is liquidated
     * @param loanId Loan ID
     * @param proceeds Liquidation proceeds in currency tokens
     */
    event CollateralLiquidated(uint256 indexed loanId, uint256 proceeds);

    /**
     * @notice Emitted when a loan adapter is updated
     * @param platform Note token or lend platform contract
     * @param loanAdapter Loan adapter contract
     */
    event LoanAdapterUpdated(address indexed platform, address loanAdapter);

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @notice Get currency token
     * @return Currency token contract
     */
    function currencyToken() external view returns (address);

    /**
     * @notice Get maximum loan duration
     * @return Maximum loan duration in seconds
     */
    function maxLoanDuration() external view returns (uint64);

    /**
     * @notice Get collateral filter contract
     * @return Collateral filter contract
     */
    function collateralFilter() external view returns (ICollateralFilter);

    /**
     * @notice Get interest rate model contract
     * @return Interest rate model contract
     */
    function interestRateModel() external view returns (IInterestRateModel);

    /**
     * @notice Get collateral liquidator contract
     * @return Collateral liquidator contract
     */
    function collateralLiquidator() external view returns (ICollateralLiquidator);

    /**
     * @notice Get loan adapter contract
     * @param platform Note token or lend platform contract
     * @return Loan adapter contract
     */
    function loanAdapters(address platform) external view returns (ILoanAdapter);

    /**
     * @notice Get list of supported platforms
     * @return Platform addresses
     */
    function supportedPlatforms() external view returns (address[] memory);

    /**************************************************************************/
    /* Note API */
    /**************************************************************************/

    /**
     * @notice Price a note
     *
     * @param noteToken Note token contract
     * @param noteTokenId Note token ID
     * @param collateralTokenIdSpec Collateral token ID specification
     * @return purchasePrice Purchase price in currency tokens
     */
    function priceNote(
        address noteToken,
        uint256 noteTokenId,
        bytes[] calldata collateralTokenIdSpec
    ) external view returns (uint256 purchasePrice);

    /**
     * @notice Sell a note
     *
     * Emits a {LoanPurchased} event.
     *
     * @param noteToken Note token contract
     * @param noteTokenId Note token ID
     * @param minPurchasePrice Minimum purchase price in currency tokens
     * @param collateralTokenIdSpec Collateral token ID specification
     * @return purchasePrice Executed purchase price in currency tokens
     */
    function sellNote(
        address noteToken,
        uint256 noteTokenId,
        uint256 minPurchasePrice,
        bytes[] calldata collateralTokenIdSpec
    ) external returns (uint256 purchasePrice);

    /**************************************************************************/
    /* Lend API */
    /**************************************************************************/

    /**
     * @notice Price a loan
     *
     * @param lendPlatform Lend platform
     * @param principal Principal amount in currency tokens
     * @param duration Duration in seconds
     * @param collateralToken Collateral token
     * @param collateralTokenId Collateral token ID
     * @param collateralTokenIdSpec Collateral token ID specification
     * @return repayment Repayment amount in currency tokens
     */
    function priceLoan(
        address lendPlatform,
        uint256 principal,
        uint64 duration,
        address collateralToken,
        uint256 collateralTokenId,
        bytes[] calldata collateralTokenIdSpec
    ) external view returns (uint256 repayment);

    /**
     * @notice Originate a loan
     *
     * Emits a {LoanOriginated} event.
     *
     * @param lendPlatform Lend platform
     * @param principal Principal amount in currency tokens
     * @param duration Duration in seconds
     * @param collateralToken Collateral token
     * @param collateralTokenId Collateral token ID
     * @param collateralTokenIdSpec Collateral token ID specification
     * @param maxRepayment Maximum repayment amount in currency tokens
     * @return loanId Loan ID
     */
    function originateLoan(
        address lendPlatform,
        uint256 principal,
        uint64 duration,
        address collateralToken,
        uint256 collateralTokenId,
        uint256 maxRepayment,
        bytes[] calldata collateralTokenIdSpec
    ) external returns (uint256 loanId);

    /**************************************************************************/
    /* Loan Callbacks */
    /**************************************************************************/

    /**
     * @notice Callback on loan repaid
     * @param loanReceipt Loan receipt
     */
    function onLoanRepaid(bytes calldata loanReceipt) external;

    /**
     * @notice Callback on loan expired
     * @param loanReceipt Loan receipt
     */
    function onLoanExpired(bytes calldata loanReceipt) external;

    /**
     * @notice Callback on loan collateral liquidated
     * @param loanReceipt Loan receipt
     * @param proceeds Liquidation proceeds in currency tokens
     */
    function onCollateralLiquidated(bytes calldata loanReceipt, uint256 proceeds) external;

    /**************************************************************************/
    /* Deposit API */
    /**************************************************************************/

    /**
     * @notice Deposit amount at depth
     *
     * Emits a {Deposited} event.
     *
     * @param depth Loan limit depth
     * @param amount Amount of currency tokens
     */
    function deposit(uint256 depth, uint256 amount) external;

    /**
     * @notice Redeem deposit shares for currency tokens. Currency tokens can
     * be withdrawn with the `withdraw()` method once the redemption is
     * processed.
     *
     * Emits a {Redeemed} event.
     *
     * @param depth Loan limit depth
     * @param shares Amount of deposit shares to redeem
     */
    function redeem(uint256 depth, uint256 shares) external;

    /**
     * @notice Get redemption available
     *
     * @param account Account
     * @param depth Loan limit depth
     * @return shares Amount of deposit shares redeemed
     * @return amount Amount of currency tokens available for withdrawal
     */
    function redemptionAvailable(address account, uint256 depth) external view returns (uint256 shares, uint256 amount);

    /**
     * @notice Withdraw a redemption that is available
     *
     * Emits a {Withdrawn} event.
     *
     * @param depth Loan limit depth
     * @return amount Amount of currency tokens withdrawn
     */
    function withdraw(uint256 depth) external returns (uint256 amount);
}