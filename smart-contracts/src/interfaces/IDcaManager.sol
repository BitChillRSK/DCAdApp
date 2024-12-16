// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
        bytes32 scheduleId; // Unique identifier of each DCA schedule
    }

    //////////////////////
    // Events ////////////
    //////////////////////
    event DcaManager__TokenBalanceUpdated(address indexed token, bytes32 indexed scheduleId, uint256 indexed amount);
    event DcaManager__TokenWithdrawn(address indexed user, address indexed token, uint256 indexed amount);
    // event DcaManager__TokenDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event DcaManager__RbtcBought(
        address indexed user, bytes32 indexed scheduleId, uint256 indexed tokenAmount, uint256 rbtcAmount
    );
    event DcaManager__rBtcWithdrawn(address indexed user, uint256 indexed rbtcAmount);
    event DcaManager__PurchaseAmountSet(
        address indexed user, bytes32 indexed scheduleId, uint256 indexed purchaseAmount
    );
    event DcaManager__PurchasePeriodSet(
        address indexed user, bytes32 indexed scheduleId, uint256 indexed purchasePeriod
    );
    event DcaManager__DcaScheduleCreated(
        address indexed user,
        address indexed token,
        bytes32 indexed scheduleId,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    );
    event DcaManager__DcaScheduleUpdated(
        address indexed user,
        address indexed token,
        bytes32 indexed scheduleId,
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
    error DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed(uint256 timeRemaining);
    error DcaManager__InexistentScheduleIndex();
    error DcaManager__InexistentScheduleId();
    error DcaManager__ScheduleIdAndIndexMismatch();
    error DcaManager__ScheduleBalanceNotEnoughForPurchase(address token, uint256 remainingBalance);
    error DcaManager__BatchPurchaseArraysLengthMismatch();
    error DcaManager__EmptyBatchPurchaseArrays();

    event DcaManager__DcaScheduleDeleted(address user, address token, bytes32 scheduleId, uint256 refundedAmount);

    error DcaManager__TokenDoesNotYieldInterest(address token);
    error DcaManager__UnauthorizedSwapper(address sender);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit a specified amount of a stablecoin into the contract for DCA operations.
     * @param token The token address of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param depositAmount The amount of the stablecoin to deposit.
     */
    function depositToken(address token, uint256 scheduleIndex, uint256 depositAmount) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param token The token address of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param withdrawalAmount The amount of the stablecoin to withdraw.
     */
    function withdrawToken(address token, uint256 scheduleIndex, uint256 withdrawalAmount) external;

    /**
     * @notice Create a new DCA schedule depositing a specified amount of a stablecoin into the contract.
     * @param token The token address of the stablecoin to deposit.
     * @param depositAmount The amount of the stablecoin to deposit.
     * @param purchaseAmount The amount of to spend periodically in buying rBTC
     * @param purchasePeriod The period for recurrent purchases
     */
    function createDcaSchedule(address token, uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod)
        external;

    /**
     * @notice Update an existing DCA schedule.
     * @param token The token address of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param depositAmount The amount of the stablecoin to deposit.
     * @param purchaseAmount The amount of to spend periodically in buying rBTC
     * @param purchasePeriod The period for recurrent purchases
     */
    function updateDcaSchedule(
        address token,
        uint256 scheduleIndex,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    ) external;

    /**
     * @dev function to delete a DCA schedule: cancels DCA and retrieves the funds
     * @param token the token used for DCA in the schedule to be deleted
     * @param scheduleId the unique identifier of the schedule to be deleted
     */
    function deleteDcaSchedule(address token, bytes32 scheduleId) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param token The token address of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param purchaseAmount The amount of to spend periodically in buying rBTC
     */
    function setPurchaseAmount(address token, uint256 scheduleIndex, uint256 purchaseAmount) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param token The token address of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param purchasePeriod The period for recurrent purchases
     */
    function setPurchasePeriod(address token, uint256 scheduleIndex, uint256 purchasePeriod) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract.
     * @param tokenHandlerFactoryAddress The address of the new token handler factory contract
     */
    function setAdminOperations(address tokenHandlerFactoryAddress) external;

    /**
     * @param buyer The address of the user on behalf of whom rBTC is going to be bought
     * @param token the stablecoin that all users in the array will spend to purchase rBTC
     * @param scheduleIndex the index of the DCA schedule
     * @param scheduleId the ID of the schedule to which the purchase corresponds
     */
    function buyRbtc(address buyer, address token, uint256 scheduleIndex, bytes32 scheduleId) external;

    /**
     * @param buyers the array of addresses of the users on behalf of whom rBTC is going to be bought
     * @notice a buyer may be featured more than once in the buyers array if two or more their schedules are due for a purchase
     * @notice we need to take extra care in the back end to not mismatch a user's address with a wrong DCA schedule
     * @param token the stablecoin that all users in the array will spend to purchase rBTC
     * @param scheduleIndexes the indexes of the DCA schedules that correspond to each user's purchase
     * @param scheduleIds the IDs of the DCA schedules that correspond to each user's purchase
     * @param purchaseAmounts the purchase amount that corresponds to each user's purchase
     * @param purchasePeriods the purchase period that corresponds to each user's purchase
     */
    function batchBuyRbtc(
        address[] memory buyers,
        address token,
        uint256[] memory scheduleIndexes,
        bytes32[] memory scheduleIds,
        uint256[] memory purchaseAmounts,
        uint256[] memory purchasePeriods
    ) external;

    /**
     * @notice Withdraw the token accumulated by a user as interest through all the DCA strategies using that token
     * @param token The token address
     */
    function withdrawInterestFromTokenHandler(address token) external;

    /**
     * @notice Withdraw a specified amount of a stablecoin from the contract as well as all the yield generated with it across all DCA schedules
     * @param token The token address of the stablecoin to deposit.
     * @param scheduleIndex The index of the DCA schedule
     * @param withdrawalAmount The amount of the stablecoin to withdraw.
     */
    function withdrawTokenAndInterest(address token, uint256 scheduleIndex, uint256 withdrawalAmount) external;

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
    function getScheduleId(address token, uint256 scheduleIndex) external view returns (bytes32);
    function getSchedulePurchasePeriod(address token, uint256 scheduleIndex) external view returns (uint256);
    function ownerGetUsersDcaSchedules(address user, address token) external view returns (DcaDetails[] memory);
    function getAdminOperationsAddress() external view returns (address);
    function getUsersDepositedTokens(address user) external view returns (address[] memory);
    function getUsers() external view returns (address[] memory);
    function getTotalNumberOfDeposits() external view returns (uint256);
    function getInterestAccruedByUser(address user, address token) external returns (uint256);

    /**
     * @dev returns the minimum period that can be set for purchases
     */
    function getMinPurchasePeriod() external returns (uint256);
}
