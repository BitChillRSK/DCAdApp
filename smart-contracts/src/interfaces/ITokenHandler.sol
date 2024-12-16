// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ITokenHandler
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the TokenHandler contract.
 */
interface ITokenHandler {
    //////////////////////
    // Events ////////////
    //////////////////////
    event TokenHandler__TokenDeposited(address indexed token, address indexed user, uint256 indexed amount);
    event TokenHandler__TokenWithdrawn(address indexed token, address indexed user, uint256 indexed amount);
    event TokenHandler__rBtcWithdrawn(address indexed user, uint256 indexed amount);
    event TokenHandler__RbtcBought(
        address indexed user,
        address indexed tokenSpent,
        uint256 indexed rBtcBought,
        bytes32 scheduleId,
        uint256 amountSpent
    );
    event TokenHandler__SuccessfulRbtcBatchPurchase(
        address indexed token, uint256 indexed totalPurchasedRbtc, uint256 indexed totalDocAmountSpent
    );

    //////////////////////
    // Errors ////////////
    //////////////////////
    error TokenHandler__InsufficientTokenAllowance(address token);
    // error TokenHandler__TokenDepositFailed(address token);
    // error TokenHandler__TokenWithdrawalFailed(address token);
    error TokenHandler__PurchaseAmountMustBeGreaterThanZero();
    error TokenHandler__PurchasePeriodMustBeGreaterThanZero();
    error TokenHandler__PurchaseAmountMustBeLowerThanHalfOfBalance();
    error TokenHandler__NoAccumulatedRbtcToWithdraw();
    error TokenHandler__rBtcWithdrawalFailed();
    error TokenHandler__OnlyDcaManagerCanCall();
    error TokenHandler__RbtcPurchaseFailed(address user, address tokenSpent);
    // error TokenHandler__FeeTransferFailed(address feeCollector, address token, uint256 feeAmount);
    error TokenHandler__RbtcBatchPurchaseFailed(address tokenSpent);

    ///////////////////////////////
    // External functions /////////
    ///////////////////////////////

    /**
     * @notice Deposit a specified amount of a stablecoin into the contract for DCA operations.
     * @param amount The amount of the stablecoin to deposit.
     * @param user The user making the deposit.
     */
    function depositToken(address user, uint256 amount) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param amount The amount of the stablecoin to withdraw.
     * @param user The user making the withdrawal.
     */
    function withdrawToken(address user, uint256 amount) external;

    /**
     * @param buyer: the user on behalf of which the contract is making the rBTC purchase
     * @param scheduleId: the ID of the DCA schedule to which the purchase belongs
     * @param purchaseAmount: the amount of the token to be spent on BTC
     * @param purchasePeriod: the DCA period of the corresopnding schedule
     * @notice this function will be called periodically through a CRON job running on a web server
     * @notice it is checked that the purchase period has elapsed, as added security on top of onlyOwner modifier
     */
    function buyRbtc(address buyer, bytes32 scheduleId, uint256 purchaseAmount, uint256 purchasePeriod) external;

    /**
     * @param buyers: the users on behalf of which the contract is making the rBTC purchases
     * @param scheduleIds: the IDs of the DCA schedules to which the purchases belong
     * @param purchaseAmounts: the amounts of the token to be spent on BTC
     * @param purchasePeriods: the DCA periods of the corresopnding schedule
     * @notice this function will be called periodically through a CRON job running on a web server
     * @notice it is checked that the purchase period has elapsed, as added security on top of onlyOwner modifier
     */
    function batchBuyRbtc(
        address[] memory buyers,
        bytes32[] memory scheduleIds,
        uint256[] memory purchaseAmounts,
        uint256[] memory purchasePeriods
    ) external;
    /**
     * @notice the user can at any time withdraw the rBTC that has been accumulated through periodical purchases
     */
    function withdrawAccumulatedRbtc(address user) external;

    /**
     * @dev returns the rBTC that has been accumulated by the user through periodical purchases
     */
    function getAccumulatedRbtcBalance() external view returns (uint256);

    /**
     * @dev to comply with ERC165
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    /**
     * @dev modifies the minimum amount of the token that can be spent in each purchase
     */
    function modifyMinPurchaseAmount(uint256 minPurchaseAmount) external;

    /**
     * @dev Returns the minimum amount of the token that can be spent in each purchase.
     * @return The minimum purchase amount in token units.
     */
    function getMinPurchaseAmount() external returns (uint256);

    /**
     * @dev Sets the parameters for the fee rate.
     * @param minFeeRate The minimum fee rate.
     * @param maxFeeRate The maximum fee rate.
     * @param minAnnualAmount The minimum annual amount for fee calculations.
     * @param maxAnnualAmount The maximum annual amount for fee calculations.
     */
    function setFeeRateParams(uint256 minFeeRate, uint256 maxFeeRate, uint256 minAnnualAmount, uint256 maxAnnualAmount)
        external;

    /**
     * @dev Sets the minimum fee rate.
     * @param minFeeRate The minimum fee rate.
     */
    function setMinFeeRate(uint256 minFeeRate) external;

    /**
     * @dev Sets the maximum fee rate.
     * @param maxFeeRate The maximum fee rate.
     */
    function setMaxFeeRate(uint256 maxFeeRate) external;

    /**
     * @dev Sets the minimum annual amount for fee calculations.
     * @param minAnnualAmount The minimum annual amount.
     */
    function setMinAnnualAmount(uint256 minAnnualAmount) external;

    /**
     * @dev Sets the maximum annual amount for fee calculations.
     * @param maxAnnualAmount The maximum annual amount.
     */
    function setMaxAnnualAmount(uint256 maxAnnualAmount) external;

    /**
     * @dev Sets the address of the fee collector.
     * @param feeCollector The address of the fee collector.
     */
    function setFeeCollectorAddress(address feeCollector) external;

    /**
     * @dev Checks if deposits yield interest.
     * @return A boolean indicating if deposits yield interest.
     */
    function depositsYieldInterest() external returns (bool);

    /**
     * @dev Withdraws the interest earned for a user.
     * @notice This function needs to be in this interface (even though it is not implemented in the TokenHandler abstract contract) because it is called by the DCA Manager contract
     * @param user The address of the user withdrawing the interest.
     * @param tokenLockedInDcaSchedules The amount of stablecoin locked in DCA schedules by the user.
     */
    function withdrawInterest(address user, uint256 tokenLockedInDcaSchedules) external;

    /**
     * @dev Checks the interest earned by a user in total.
     * @notice This function needs to be in this interface (even though it is not implemented in the TokenHandler abstract contract) because it is called by the DCA Manager contract
     * @param user The address of the user.
     * @param tokenLockedInDcaSchedules The amount of stablecoin locked in DCA schedules by the user in total.
     */
    function getAccruedInterest(address user, uint256 tokenLockedInDcaSchedules) external returns (uint256);
}
