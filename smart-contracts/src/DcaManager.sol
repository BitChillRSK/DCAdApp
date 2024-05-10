// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDcaManager} from "./interfaces/IDcaManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ITokenHandler} from "./interfaces/ITokenHandler.sol";
import {AdminOperations} from "./AdminOperations.sol";

/**
 * @title DCA Manager
 * @author BitChill team: Antonio María Rodríguez-Ynyesto Sánchez
 * @notice This contract will be used to save and edit the users' DCA strategies
 * @custom:unaudited This is an unaudited contract
 */
contract DcaManager is IDcaManager, Ownable, ReentrancyGuard {
    ///////////////////////////////
    // State variables ////////////
    ///////////////////////////////
    AdminOperations s_adminOperations;
    address[] s_acceptedStableCoins;
    /**
     * @notice Each user may open positions with more than one stablecoin and with different schedules
     */
    mapping(address user => mapping(address stableCoin => bool isDeposited)) private s_tokenDeposited; // User to token deposited flag
    mapping(address user => address[] usersDepositedTokens) private s_depositedTokens;
    mapping(address user => mapping(address depositedTokens => DcaDetails[] usersDcaPositions)) private s_dcaPositions;
    mapping(address user => bool registered) s_userRegistered; // Mapping to check if a user has (or ever had) an open DCA position
    address[] private s_users; // Users that have deposited stablecoins in the DCA dApp

    //////////////////////
    // Functions /////////
    //////////////////////

    /**
     * @notice the contract is ownable and after deployment its ownership shall be transferred to the wallet associated to the CRON job
     * @notice the DCA contract inherits from OZ's Ownable, which is the secure, standard way to handle ownership
     */
    constructor(address adminOperationsAddress) Ownable(msg.sender) {
        s_adminOperations = AdminOperations(adminOperationsAddress);
    }

    /**
     * @notice deposit the full DOC amount for DCA on the contract
     * @param depositAmount: the amount of DOC to deposit
     */
    function depositToken(address token, uint256 scheduleIndex, uint256 depositAmount) external override nonReentrant {
        _depositToken(token, scheduleIndex, depositAmount);
        // emit DcaManager__TokenDeposited(msg.sender, token, depositAmount);
        emit DcaManager__TokenBalanceUpdated(
            token, scheduleIndex, s_dcaPositions[msg.sender][token][scheduleIndex].tokenBalance
        );
    }

    /**
     * @param purchaseAmount: the amount of DOC to swap periodically for rBTC
     * @notice the amount cannot be greater than or equal to half of the deposited amount
     */
    function setPurchaseAmount(address token, uint256 scheduleIndex, uint256 purchaseAmount) external override {
        _setPurchaseAmount(token, scheduleIndex, purchaseAmount);
        emit PurchaseAmountSet(msg.sender, purchaseAmount);
    }

    /**
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     * @notice the period
     */
    function setPurchasePeriod(address token, uint256 scheduleIndex, uint256 purchasePeriod) external override {
        _setPurchasePeriod(token, scheduleIndex, purchasePeriod);
        emit PurchasePeriodSet(msg.sender, purchasePeriod);
    }

    /**
     * @notice deposit the full stablecoin amount for DCA on the contract, set the period and the amount for purchases
     * @param token: the token address of stablecoin to deposit
     * @param scheduleIndex: the index of the schedule to create or update
     * @param depositAmount: the amount of stablecoin to deposit
     * @param purchaseAmount: the amount of stablecoin to swap periodically for rBTC
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     */
    function createOrUpdateDcaSchedule(
        address token,
        uint256 scheduleIndex,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    ) external override {
        _depositToken(token, scheduleIndex, depositAmount);
        _setPurchaseAmount(token, scheduleIndex, purchaseAmount);
        _setPurchasePeriod(token, scheduleIndex, purchasePeriod);
        emit DcaManager__newDcaScheduleCreated(
            msg.sender, token, scheduleIndex, depositAmount, purchaseAmount, purchasePeriod
        );
    }

    /**
     * @notice withdraw amount for DCA on the contract
     * @param token: the token to withdraw
     * @param withdrawalAmount: the amount to withdraw
     */
    function withdrawToken(address token, uint256 scheduleIndex, uint256 withdrawalAmount)
        external
        override
        nonReentrant
    {
        uint256 tokenBalance = s_dcaPositions[msg.sender][token][scheduleIndex].tokenBalance;
        if (withdrawalAmount > tokenBalance) {
            revert DcaManager__WithdrawalAmountExceedsBalance(token, withdrawalAmount, tokenBalance);
        }
        ITokenHandler tokenHandler = _handler(token);
        s_dcaPositions[msg.sender][token][scheduleIndex].tokenBalance -= withdrawalAmount;
        tokenHandler.withdrawToken(msg.sender, withdrawalAmount);
        emit DcaManager__TokenWithdrawn(msg.sender, token, withdrawalAmount);
        emit DcaManager__TokenBalanceUpdated(
            token, scheduleIndex, s_dcaPositions[msg.sender][token][scheduleIndex].tokenBalance
        );
    }

    /**
     * @notice Withdraw the rBtc accumulated by a user through all the DCA strategies created using a given stablecoin
     * @param token The token address of the stablecoin
     */
    function withdrawRbtcFromTokenHandler(address token) external nonReentrant {
        ITokenHandler tokenHandler = _handler(token);
        tokenHandler.withdrawAccumulatedRbtc(msg.sender);
    }

    /**
     * @notice Withdraw all of the rBTC accumulated by a user through their various DCA strategies
     */
    function withdrawAllAccmulatedRbtc() external nonReentrant {
        for (uint256 i; i < s_depositedTokens[msg.sender].length; i++) {
            ITokenHandler tokenHandler = _handler(s_depositedTokens[msg.sender][i]);
            tokenHandler.withdrawAccumulatedRbtc(msg.sender);
        }
    }

    function buyRbtc(address buyer, address token, uint256 scheduleIndex) external nonReentrant onlyOwner {
        // If this is not the first purchase for this schedule, check that period has elapsed before making a new purchase
        uint256 lastPurchaseTimestamp = s_dcaPositions[buyer][token][scheduleIndex].lastPurchaseTimestamp;
        uint256 purchasePeriod = s_dcaPositions[buyer][token][scheduleIndex].purchasePeriod;
        if (lastPurchaseTimestamp > 0 && block.timestamp - lastPurchaseTimestamp < purchasePeriod) {
            revert DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed(lastPurchaseTimestamp + purchasePeriod - block.timestamp);
        }

        uint256 purchaseAmount = s_dcaPositions[buyer][token][scheduleIndex].purchaseAmount;
        s_dcaPositions[buyer][token][scheduleIndex].tokenBalance -= purchaseAmount;
        s_dcaPositions[buyer][token][scheduleIndex].lastPurchaseTimestamp = block.timestamp;

        ITokenHandler tokenHandler = _handler(token);
        tokenHandler.buyRbtc(buyer, purchaseAmount);
    }

    /**
     * @notice update the token handler factory contract
     * @param adminOperationsAddress: the address of token handler factory
     */
    function setAdminOperations(address adminOperationsAddress) external override onlyOwner {
        s_adminOperations = AdminOperations(adminOperationsAddress);
    }

    ///////////////////////////////
    // Internal functions /////////
    ///////////////////////////////

    /**
     * @param purchaseAmount: the amount of DOC to swap periodically for rBTC
     * @notice the amount cannot be greater than or equal to half of the deposited amount
     */
    function _setPurchaseAmount(address token, uint256 scheduleIndex, uint256 purchaseAmount) internal {
        if (purchaseAmount <= 0) revert DcaManager__PurchaseAmountMustBeGreaterThanZero();
        if (purchaseAmount > s_dcaPositions[msg.sender][token][scheduleIndex].tokenBalance / 2) {
            revert DcaManager__PurchaseAmountMustBeLowerThanHalfOfBalance();
        } //At least two DCA purchases
        s_dcaPositions[msg.sender][token][scheduleIndex].purchaseAmount = purchaseAmount;
    }

    /**
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     * @notice the period
     */
    function _setPurchasePeriod(address token, uint256 scheduleIndex, uint256 purchasePeriod) internal {
        if (purchasePeriod <= 0) revert DcaManager__PurchasePeriodMustBeGreaterThanZero();
        s_dcaPositions[msg.sender][token][scheduleIndex].purchasePeriod = purchasePeriod;
    }

    /**
     * @notice deposit the full stablecoin amount for DCA on the contract
     * @param token: the token to deposit
     * @param depositAmount: the amount to deposit
     */
    function _depositToken(address token, uint256 scheduleIndex, uint256 depositAmount) internal {
        ITokenHandler tokenHandler = _handler(token);
        // if (!_isTokenDeposited(token)) s_depositedTokens[msg.sender].push(token);
        if (!s_tokenDeposited[msg.sender][token]) {
            s_tokenDeposited[msg.sender][token] = true;
            s_depositedTokens[msg.sender].push(token);
        }
        if (!s_userRegistered[msg.sender]) {
            s_userRegistered[msg.sender] = true;
            s_users.push(msg.sender);
        }

        uint256 numOfSchedules = s_dcaPositions[msg.sender][token].length;
        if (numOfSchedules < scheduleIndex) revert DcaManager__CannotCreateScheduleSkippingIndexes();

        // If the DCA schedule doesn't exist, making a deposit will intialize it
        if (numOfSchedules == scheduleIndex) {
            s_dcaPositions[msg.sender][token].push(DcaDetails(0, 0, 0, 0));
        }
        tokenHandler.depositToken(msg.sender, depositAmount);
        s_dcaPositions[msg.sender][token][scheduleIndex].tokenBalance += depositAmount;
    }

    function _handler(address token) internal view returns (ITokenHandler) {
        address tokenHandlerAddress = s_adminOperations.getTokenHandler(token);
        if (tokenHandlerAddress == address(0)) revert DcaManager__TokenNotAccepted();
        return ITokenHandler(tokenHandlerAddress);
    }

    // function _isTokenDeposited(address token) internal view returns (bool) {
    // for (uint256 i; i < s_depositedTokens[msg.sender].length; i++) {
    //     if (s_depositedTokens[msg.sender][i] == token) return true;
    // }
    // return false;
    // }

    //////////////////////
    // Getter functions //
    //////////////////////

    function getMyDcaPositions(address token) external view returns (DcaDetails[] memory) {
        return s_dcaPositions[msg.sender][token];
    }

    function getScheduleTokenBalance(address token, uint256 scheduleIndex) external view returns (uint256) {
        return s_dcaPositions[msg.sender][token][scheduleIndex].tokenBalance;
    }

    function getSchedulePurchaseAmount(address token, uint256 scheduleIndex) external view returns (uint256) {
        return s_dcaPositions[msg.sender][token][scheduleIndex].purchaseAmount;
    }

    function getSchedulePurchasePeriod(address token, uint256 scheduleIndex) external view returns (uint256) {
        return s_dcaPositions[msg.sender][token][scheduleIndex].purchasePeriod;
    }

    function ownerGetUsersDcaPositions(address user, address token)
        external
        view
        onlyOwner
        returns (DcaDetails[] memory)
    {
        return s_dcaPositions[user][token];
    }

    function getUsers() external view onlyOwner returns (address[] memory) {
        return s_users;
    }

    function getTotalNumberOfDeposits() external view returns (uint256) {
        return s_users.length;
    }
}
