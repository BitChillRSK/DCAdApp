// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IDcaManager
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the DcaManager contract.
 */
interface IDcaManager {
    ////////////////////////
    // Type declarations ///
    ////////////////////////
    struct DcaDetails {
        uint256 tokenBalance; // Stablecoin amount deposited by the user
        uint256 purchaseAmount; // Stablecoin amount to spend periodically on rBTC
        uint256 purchasePeriod; // Time between purchases in seconds
        uint256 lastPurchaseTimestamp; // Timestamp of the latest purchase
    }

    //////////////////////
    // Events ////////////
    //////////////////////
    event DcaManager__TokenBalanceUpdated(address indexed token, uint256 indexed scheduleIndex, uint256 indexed amount);
    event DcaManager__TokenWithdrawn(address indexed user, address indexed token, uint256 indexed amount);
    // event DcaManager__TokenDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event RbtcBought(address indexed user, uint256 indexed docAmount, uint256 indexed rbtcAmount);
    event rBtcWithdrawn(address indexed user, uint256 indexed rbtcAmount);
    event PurchaseAmountSet(address indexed user, uint256 indexed purchaseAmount);
    event PurchasePeriodSet(address indexed user, uint256 indexed purchasePeriod);
    event DcaManager__DcaScheduleCreated(
        address indexed user,
        address indexed token,
        uint256 indexed scheduleIndex,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    );
    event DcaManager__DcaScheduleUpdated(
        address indexed user,
        address indexed token,
        uint256 indexed scheduleIndex,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    );

    //////////////////////
    // Errors ////////////
    //////////////////////
    error DcaManager__TokenNotAccepted();
    error DcaManager__DepositAmountMustBeGreaterThanZero();
    error DcaManager__WithdrawalAmountMustBeGreaterThanZero();
    error DcaManager__WithdrawalAmountExceedsBalance(address token, uint256 amount, uint256 balance);
    error DcaManager__PurchaseAmountMustBeGreaterThanMinimum(address token);
    error DcaManager__PurchasePeriodMustBeGreaterThanMin();
    error DcaManager__PurchaseAmountMustBeLowerThanHalfOfBalance();
    // error DcaManager__OnlyMocProxyCanSendRbtcToDcaContract();
    error DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed(uint256 timeRemaining);
    // error DcaManager__CannotDepositInTropykusMoreThanBalance();
    // error DcaManager__DocApprovalForKdocContractFailed();
    // error DcaManager__TropykusDepositFailed();
    error DcaManager__DcaScheduleDoesNotExist();
    error DcaManager__InexistentSchedule();
    error DcaManager__ScheduleBalanceNotEnoughForPurchase(address token, uint256 remainingBalance);
    error DcaManager__BatchPurchaseArraysLengthMismatch();
    error DcaManager__EmptyBatchPurchaseArrays();
    event DcaManager__DcaScheduleDeleted(address user, address token, uint256 scheduleIndex, uint256 refundedAmount);
    error DcaManager__TokenDoesNotYieldInterest(address token);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit a specified amount of a stablecoin into the contract for DCA operations.
     * @param tokenAddress The token addreess of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param depositAmount The amount of the stablecoin to deposit.
     */
    function depositToken(address tokenAddress, uint256 scheduleIndex, uint256 depositAmount) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param tokenAddress The token addreess of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param withdrawalAmount The amount of the stablecoin to withdraw.
     */
    function withdrawToken(address tokenAddress, uint256 scheduleIndex, uint256 withdrawalAmount) external;

    /**
     * @notice Create a new DCA schedule depositing a specified amount of a stablecoin into the contract.
     * @param tokenAddress The token addreess of the stablecoin to deposit.
     * @param depositAmount The amount of the stablecoin to deposit.
     * @param purchaseAmount The amount of to spend periodically in buying rBTC
     * @param purchasePeriod The period for recurrent purchases
     */
    function createDcaSchedule(
        address tokenAddress,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    ) external;

    /**
     * @notice Update an existing DCA schedule.
     * @param tokenAddress The token addreess of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param depositAmount The amount of the stablecoin to deposit.
     * @param purchaseAmount The amount of to spend periodically in buying rBTC
     * @param purchasePeriod The period for recurrent purchases
     */
    function updateDcaSchedule(
        address tokenAddress,
        uint256 scheduleIndex,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    ) external;

    /**
     * @dev function to delete a DCA schedule: cancels DCA and retrieves the funds
     * @param token the token used for DCA in the schedule to be deleted
     * @param scheduleIndex the index of the schedule
     */
    function deleteDcaSchedule(address token, uint256 scheduleIndex) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param tokenAddress The token address of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param purchaseAmount The amount of to spend periodically in buying rBTC
     */
    function setPurchaseAmount(address tokenAddress, uint256 scheduleIndex, uint256 purchaseAmount) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param tokenAddress The token address of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param purchasePeriod The period for recurrent purchases
     */
    function setPurchasePeriod(address tokenAddress, uint256 scheduleIndex, uint256 purchasePeriod) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param tokenHandlerFactoryAddress The address of the new token handler factory contract
     */
    function setAdminOperations(address tokenHandlerFactoryAddress) external;

    /**
     * @notice Withdraw the rBtc accumulated by a user through all the DCA strategies created using a given stablecoin
     * @param token The token address of the stablecoin
     */
    function withdrawRbtcFromTokenHandler(address token) external;

    /**
     * @notice Withdraw all of the rBTC accumulated by a user through their various DCA strategies
     */
    function withdrawAllAccmulatedRbtc() external;

    /**
     * @dev modifies the minimum period that can be set for purchases
     */
    function modifyMinPurchasePeriod(uint256 minPurchasePeriod) external;


    //////////////////////
    // Getter functions //
    //////////////////////

    function getMyDcaSchedules(address token) external view returns (DcaDetails[] memory);
    function getScheduleTokenBalance(address token, uint256 scheduleIndex) external view returns (uint256);
    function getSchedulePurchaseAmount(address token, uint256 scheduleIndex) external view returns (uint256);
    function getSchedulePurchasePeriod(address token, uint256 scheduleIndex) external view returns (uint256);
    function ownerGetUsersDcaSchedules(address user, address token) external view returns (DcaDetails[] memory);
    function getUsers() external view returns (address[] memory);
    function getTotalNumberOfDeposits() external view returns (uint256);
    
    /**
     * @dev returns the minimum period that can be set for purchases
     */
    function getMinPurchasePeriod() external returns (uint256);
}
