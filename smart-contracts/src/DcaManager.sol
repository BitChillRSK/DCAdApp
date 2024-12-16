// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDcaManager} from "./interfaces/IDcaManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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
    AdminOperations private s_adminOperations;

    /**
     * @notice Each user may create different schedules with one or more stablecoins
     */
    mapping(address user => mapping(address stableCoin => bool isDeposited)) private s_tokenIsDeposited; // User to token deposited flag
    mapping(address user => address[] depositedTokens) private s_usersDepositedTokens;
    mapping(address user => mapping(address tokenDeposited => DcaDetails[] usersDcaSchedules)) private s_dcaSchedules;
    // mapping(address user => mapping(address tokenDeposited => mapping(bytes32 scheduleId => DcaDetails scheduleDetails))) private s_dcaSchedules;
    mapping(address user => bool registered) s_userRegistered; // Mapping to check if a user has (or ever had) an open DCA position
    address[] private s_users; // Users that have deposited stablecoins in the DCA dApp
    uint256 private s_minPurchasePeriod = 1 days; // At most one purchase each day

    //////////////////////
    // Modifiers /////////
    //////////////////////
    modifier validateIndex(address token, uint256 scheduleIndex) {
        if (scheduleIndex >= s_dcaSchedules[msg.sender][token].length) {
            revert DcaManager__InexistentScheduleIndex();
        }
        _;
    }

    modifier onlySwapper() {
        if (!s_adminOperations.hasRole(s_adminOperations.SWAPPER_ROLE(), msg.sender)) {
            revert DcaManager__UnauthorizedSwapper(msg.sender);
        }
        _;
    }

    //////////////////////
    // Functions /////////
    //////////////////////

    /**
     * @notice the contract is ownable and after deployment its ownership shall be transferred to the wallet associated to the CRON job
     * @notice the DCA contract inherits from OZ's Ownable, which is the secure, standard way to handle ownership
     */
    constructor(address adminOperationsAddress) {
        s_adminOperations = AdminOperations(adminOperationsAddress);
    }

    /**
     * @notice deposit the full DOC amount for DCA on the contract
     * @param depositAmount: the amount of DOC to deposit
     */
    function depositToken(address token, uint256 scheduleIndex, uint256 depositAmount)
        external
        override
        nonReentrant
        validateIndex(token, scheduleIndex)
    {
        _validateDeposit(token, depositAmount);
        DcaDetails storage dcaSchedule = s_dcaSchedules[msg.sender][token][scheduleIndex];
        dcaSchedule.tokenBalance += depositAmount;
        _handler(token).depositToken(msg.sender, depositAmount);
        // emit DcaManager__TokenDeposited(msg.sender, token, depositAmount);
        emit DcaManager__TokenBalanceUpdated(token, dcaSchedule.scheduleId, dcaSchedule.tokenBalance);
    }

    /**
     * @param purchaseAmount: the amount of DOC to swap periodically for rBTC
     * @notice the amount cannot be greater than or equal to half of the deposited amount
     */
    function setPurchaseAmount(address token, uint256 scheduleIndex, uint256 purchaseAmount)
        external
        override
        validateIndex(token, scheduleIndex)
    {
        DcaDetails storage dcaSchedule = s_dcaSchedules[msg.sender][token][scheduleIndex];
        _validatePurchaseAmount(token, purchaseAmount, dcaSchedule.tokenBalance);
        dcaSchedule.purchaseAmount = purchaseAmount;
        emit DcaManager__PurchaseAmountSet(msg.sender, dcaSchedule.scheduleId, purchaseAmount);
    }

    /**
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     * @notice the period
     */
    function setPurchasePeriod(address token, uint256 scheduleIndex, uint256 purchasePeriod)
        external
        override
        validateIndex(token, scheduleIndex)
    {
        DcaDetails storage dcaSchedule = s_dcaSchedules[msg.sender][token][scheduleIndex];
        _validatePurchasePeriod(purchasePeriod);
        dcaSchedule.purchasePeriod = purchasePeriod;
        emit DcaManager__PurchasePeriodSet(msg.sender, dcaSchedule.scheduleId, purchasePeriod);
    }

    /**
     * @notice deposit the full stablecoin amount for DCA on the contract, set the period and the amount for purchases
     * @param token: the token address of stablecoin to deposit
     * @param depositAmount: the amount of stablecoin to deposit
     * @param purchaseAmount: the amount of stablecoin to swap periodically for rBTC
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     */
    function createDcaSchedule(address token, uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod)
        external
        override
    {
        _validatePurchasePeriod(purchasePeriod);
        _validateDeposit(token, depositAmount);
        _handler(token).depositToken(msg.sender, depositAmount);

        bytes32 scheduleId =
            keccak256(abi.encodePacked(msg.sender, block.timestamp, s_dcaSchedules[msg.sender][token].length));

        DcaDetails memory dcaSchedule = DcaDetails(
            depositAmount,
            purchaseAmount,
            purchasePeriod,
            0, // lastPurchaseTimestamp
            scheduleId
        );

        _validatePurchaseAmount(token, purchaseAmount, dcaSchedule.tokenBalance);

        s_dcaSchedules[msg.sender][token].push(dcaSchedule);
        emit DcaManager__DcaScheduleCreated(
            msg.sender, token, scheduleId, depositAmount, purchaseAmount, purchasePeriod
        );
    }

    /**
     * @notice deposit the full stablecoin amount for DCA on the contract, set the period and the amount for purchases
     * @param token: the token address of stablecoin to deposit
     * @param scheduleIndex: the index of the schedule to create or update
     * @param depositAmount: the amount of stablecoin to add to the existing schedule (final token balance for the schedule is the previous balance + depositAmount)
     * @param purchaseAmount: the amount of stablecoin to swap periodically for rBTC
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     */
    function updateDcaSchedule(
        address token,
        uint256 scheduleIndex,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    ) external override validateIndex(token, scheduleIndex) {
        DcaDetails memory dcaSchedule = s_dcaSchedules[msg.sender][token][scheduleIndex];

        if (purchasePeriod > 0) {
            _validatePurchasePeriod(purchasePeriod);
            dcaSchedule.purchasePeriod = purchasePeriod;
        }
        if (depositAmount > 0) {
            _validateDeposit(token, depositAmount);
            dcaSchedule.tokenBalance += depositAmount;
            _handler(token).depositToken(msg.sender, depositAmount);
        }
        if (purchaseAmount > 0) {
            _validatePurchaseAmount(token, purchaseAmount, dcaSchedule.tokenBalance);
            dcaSchedule.purchaseAmount = purchaseAmount;
        }

        s_dcaSchedules[msg.sender][token][scheduleIndex] = dcaSchedule;

        emit DcaManager__DcaScheduleUpdated(
            msg.sender, token, dcaSchedule.scheduleId, depositAmount, purchaseAmount, purchasePeriod
        );
    }

    function deleteDcaSchedule(address token, bytes32 scheduleId) external nonReentrant {
        DcaDetails[] storage schedules = s_dcaSchedules[msg.sender][token];

        uint256 scheduleIndex;
        bool found = false;

        // Find the schedule by scheduleId
        for (uint256 i = 0; i < schedules.length; i++) {
            if (schedules[i].scheduleId == scheduleId) {
                scheduleIndex = i;
                found = true;
                break;
            }
        }

        if (!found) revert DcaManager__InexistentScheduleId();

        // Store the balance and scheduleId before modifying the array
        uint256 tokenBalance = schedules[scheduleIndex].tokenBalance;

        // Remove the schedule
        uint256 lastIndex = schedules.length - 1;
        if (scheduleIndex != lastIndex) {
            // Overwrite the schedule getting deleted with the one in the last index
            schedules[scheduleIndex] = schedules[lastIndex];
        }
        // Remove the last schedule
        schedules.pop();

        // Withdraw all balance
        _handler(token).withdrawToken(msg.sender, tokenBalance);

        // Emit event
        emit DcaManager__DcaScheduleDeleted(msg.sender, token, scheduleId, tokenBalance);
    }

    /**
     * @notice withdraw amount for DCA from the contract
     * @param token: the token to withdraw
     * @param withdrawalAmount: the amount to withdraw
     */
    function withdrawToken(address token, uint256 scheduleIndex, uint256 withdrawalAmount)
        external
        override
        nonReentrant
    {
        _withdrawToken(token, scheduleIndex, withdrawalAmount);
    }

    function buyRbtc(address buyer, address token, uint256 scheduleIndex, bytes32 scheduleId)
        external
        override
        nonReentrant
        // onlyOwner
        onlySwapper
    {
        (uint256 purchaseAmount, uint256 purchasePeriod) =
            _rBtcPurchaseChecksEffects(buyer, token, scheduleIndex, scheduleId);
        _handler(token).buyRbtc(buyer, scheduleId, purchaseAmount, purchasePeriod);
    }

    /**
     * @param buyers the array of addresses of the users on behalf of whom rBTC is going to be bought
     * @notice a buyer may be featured more than once in the buyers array if two or more their schedules are due for a purchase
     * @notice we need to take extra care in the back end to not mismatch a user's address with a wrong DCA schedule
     * @param token the stablecoin that all users in the array will spend to purchase rBTC
     * @param scheduleIndexes the indexes of the DCA schedules that correspond to each user's purchase
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
    ) external override nonReentrant /*onlyOwner*/ onlySwapper {
        uint256 numOfPurchases = buyers.length;
        if (numOfPurchases == 0) revert DcaManager__EmptyBatchPurchaseArrays();
        if (
            numOfPurchases != scheduleIndexes.length || numOfPurchases != scheduleIds.length
                || numOfPurchases != purchaseAmounts.length || numOfPurchases != purchasePeriods.length
        ) revert DcaManager__BatchPurchaseArraysLengthMismatch();
        for (uint256 i; i < numOfPurchases; ++i) {
            /**
             * @notice Update balances and timestamps, returned values are not needed here
             */
            _rBtcPurchaseChecksEffects(buyers[i], token, scheduleIndexes[i], scheduleIds[i]);
            // TODO: Add check that purchaseAmount and purchasePeriod match the schedule's?
        }
        _handler(token).batchBuyRbtc(buyers, scheduleIds, purchaseAmounts, purchasePeriods);
    }

    /**
     * @notice Users can withdraw the rBtc accumulated through all the DCA strategies created using a given stablecoin
     * @param token The token address of the stablecoin
     */
    function withdrawRbtcFromTokenHandler(address token) external override nonReentrant {
        _handler(token).withdrawAccumulatedRbtc(msg.sender);
    }

    /**
     * @notice Withdraw all of the rBTC accumulated by a user through their various DCA strategies
     */
    function withdrawAllAccmulatedRbtc() external override nonReentrant {
        for (uint256 i; i < s_usersDepositedTokens[msg.sender].length; ++i) {
            _handler(s_usersDepositedTokens[msg.sender][i]).withdrawAccumulatedRbtc(msg.sender);
        }
    }

    /**
     * @notice withdraw amount for DCA from the contract, as well as the yield generated across all DCA schedules
     * @param token: the token of which to withdraw the specified amount and yield
     * @param withdrawalAmount: the amount to withdraw
     */
    function withdrawTokenAndInterest(address token, uint256 scheduleIndex, uint256 withdrawalAmount)
        external
        override
        nonReentrant
    {
        _withdrawToken(token, scheduleIndex, withdrawalAmount);
        _withdrawInterest(token);
    }

    /**
     * @dev Users can withdraw the stablecoin interests accrued by the deposits they made
     * @param token The address of the token to withdraw
     */
    function withdrawInterestFromTokenHandler(address token) external override nonReentrant {
        _withdrawInterest(token);
    }

    /**
     * @notice update the admin operations contract
     * @param adminOperationsAddress: the address of admin operations
     */
    function setAdminOperations(address adminOperationsAddress) external override onlyOwner {
        s_adminOperations = AdminOperations(adminOperationsAddress);
    }

    /**
     * @notice modify the minimum period between purchases
     * @param minPurchasePeriod: the new period
     */
    function modifyMinPurchasePeriod(uint256 minPurchasePeriod) external override onlyOwner {
        s_minPurchasePeriod = minPurchasePeriod;
    }

    ///////////////////////////////
    // Internal functions /////////
    ///////////////////////////////

    /**
     * @notice validate that the purchase amount to be set is valid
     * @param token: the token spent on DCA
     * @param purchaseAmount: the purchase amount to validate
     * @param tokenBalance: the current balance of the token in that DCA schedule
     */
    function _validatePurchaseAmount(address token, uint256 purchaseAmount, uint256 tokenBalance) internal {
        if (purchaseAmount < _handler(token).getMinPurchaseAmount()) {
            revert DcaManager__PurchaseAmountMustBeGreaterThanMinimum(token);
        }
        /**
         * @notice Purchase amount must be at least twice the balance of the token in the contract to allow at least two DCA purchases
         */
        if (purchaseAmount > (tokenBalance) / 2) {
            revert DcaManager__PurchaseAmountMustBeLowerThanHalfOfBalance();
        }
    }

    function _validatePurchasePeriod(uint256 purchasePeriod) internal view {
        if (purchasePeriod < s_minPurchasePeriod) revert DcaManager__PurchasePeriodMustBeGreaterThanMin();
    }

    /**
     * @notice deposit the full stablecoin amount for DCA on the contract
     * @param token: the token to deposit
     * @param depositAmount: the amount to deposit
     */
    function _validateDeposit(address token, uint256 depositAmount) internal {
        if (depositAmount <= 0) revert DcaManager__DepositAmountMustBeGreaterThanZero();
        // if (!_isTokenDeposited(token)) s_usersDepositedTokens[msg.sender].push(token);
        if (!s_tokenIsDeposited[msg.sender][token]) {
            s_tokenIsDeposited[msg.sender][token] = true;
            s_usersDepositedTokens[msg.sender].push(token);
        }
        if (!s_userRegistered[msg.sender]) {
            s_userRegistered[msg.sender] = true;
            s_users.push(msg.sender);
        }
    }

    function _handler(address token) internal view returns (ITokenHandler) {
        address tokenHandlerAddress = s_adminOperations.getTokenHandler(token);
        if (tokenHandlerAddress == address(0)) revert DcaManager__TokenNotAccepted();
        return ITokenHandler(tokenHandlerAddress);
    }

    function _rBtcPurchaseChecksEffects(address buyer, address token, uint256 scheduleIndex, bytes32 scheduleId)
        internal
        returns (uint256, uint256)
    {
        DcaDetails storage dcaSchedule = s_dcaSchedules[buyer][token][scheduleIndex];

        if (scheduleId != dcaSchedule.scheduleId) revert DcaManager__ScheduleIdAndIndexMismatch();

        // If this is not the first purchase for this schedule, check that period has elapsed before making a new purchase
        uint256 lastPurchaseTimestamp = dcaSchedule.lastPurchaseTimestamp;
        uint256 purchasePeriod = dcaSchedule.purchasePeriod;
        if (lastPurchaseTimestamp > 0 && block.timestamp - lastPurchaseTimestamp < purchasePeriod) {
            revert DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed(
                lastPurchaseTimestamp + purchasePeriod - block.timestamp
            );
        }

        if (dcaSchedule.purchaseAmount > dcaSchedule.tokenBalance) {
            revert DcaManager__ScheduleBalanceNotEnoughForPurchase(token, dcaSchedule.tokenBalance);
        }
        dcaSchedule.tokenBalance -= dcaSchedule.purchaseAmount;
        dcaSchedule.lastPurchaseTimestamp = block.timestamp;

        return (dcaSchedule.purchaseAmount, purchasePeriod);
    }

    function _withdrawToken(address token, uint256 scheduleIndex, uint256 withdrawalAmount) internal {
        if (withdrawalAmount <= 0) revert DcaManager__WithdrawalAmountMustBeGreaterThanZero();
        uint256 tokenBalance = s_dcaSchedules[msg.sender][token][scheduleIndex].tokenBalance;
        if (withdrawalAmount > tokenBalance) {
            revert DcaManager__WithdrawalAmountExceedsBalance(token, withdrawalAmount, tokenBalance);
        }
        DcaDetails storage dcaSchedule = s_dcaSchedules[msg.sender][token][scheduleIndex];
        dcaSchedule.tokenBalance -= withdrawalAmount;
        // s_dcaSchedules[msg.sender][token][scheduleIndex].tokenBalance -= withdrawalAmount;
        _handler(token).withdrawToken(msg.sender, withdrawalAmount);
        emit DcaManager__TokenWithdrawn(msg.sender, token, withdrawalAmount);
        emit DcaManager__TokenBalanceUpdated(
            token, dcaSchedule.scheduleId, s_dcaSchedules[msg.sender][token][scheduleIndex].tokenBalance
        );
    }

    function _withdrawInterest(address token) internal {
        ITokenHandler tokenHandler = _handler(token);
        if (!tokenHandler.depositsYieldInterest()) revert DcaManager__TokenDoesNotYieldInterest(token);
        uint256 lockedTokenAmount;
        DcaDetails[] memory dcaSchedules = s_dcaSchedules[msg.sender][token];
        for (uint256 i; i < dcaSchedules.length; ++i) {
            lockedTokenAmount += dcaSchedules[i].tokenBalance;
        }
        tokenHandler.withdrawInterest(msg.sender, lockedTokenAmount);
    }

    // function _isTokenDeposited(address token) internal view returns (bool) {
    // for (uint256 i; i < s_usersDepositedTokens[msg.sender].length; ++i) {
    //     if (s_usersDepositedTokens[msg.sender][i] == token) return true;
    // }
    // return false;
    // }

    //////////////////////
    // Getter functions //
    //////////////////////

    function getMyDcaSchedules(address token) external view override returns (DcaDetails[] memory) {
        return s_dcaSchedules[msg.sender][token];
    }

    function getScheduleTokenBalance(address token, uint256 scheduleIndex)
        external
        view
        override
        validateIndex(token, scheduleIndex)
        returns (uint256)
    {
        return s_dcaSchedules[msg.sender][token][scheduleIndex].tokenBalance;
    }

    function getSchedulePurchaseAmount(address token, uint256 scheduleIndex)
        external
        view
        override
        validateIndex(token, scheduleIndex)
        returns (uint256)
    {
        return s_dcaSchedules[msg.sender][token][scheduleIndex].purchaseAmount;
    }

    function getSchedulePurchasePeriod(address token, uint256 scheduleIndex)
        external
        view
        override
        validateIndex(token, scheduleIndex)
        returns (uint256)
    {
        return s_dcaSchedules[msg.sender][token][scheduleIndex].purchasePeriod;
    }

    function getScheduleId(address token, uint256 scheduleIndex) external view override returns (bytes32) {
        return s_dcaSchedules[msg.sender][token][scheduleIndex].scheduleId;
    }

    function ownerGetUsersDcaSchedules(address user, address token)
        external
        view
        override
        onlyOwner
        returns (DcaDetails[] memory)
    {
        return s_dcaSchedules[user][token];
    }

    function getUsers() external view override onlyOwner returns (address[] memory) {
        return s_users;
    }

    function getTotalNumberOfDeposits() external view override returns (uint256) {
        return s_users.length;
    }

    function getAdminOperationsAddress() external view override returns (address) {
        return address(s_adminOperations);
    }

    function getMinPurchasePeriod() external view override returns (uint256) {
        return s_minPurchasePeriod;
    }

    function getUsersDepositedTokens(address user) external view override returns (address[] memory) {
        return s_usersDepositedTokens[user];
    }

    function getInterestAccruedByUser(address user, address token) external override returns (uint256) {
        ITokenHandler tokenHandler = _handler(token);
        if (!tokenHandler.depositsYieldInterest()) revert DcaManager__TokenDoesNotYieldInterest(token);
        uint256 lockedTokenAmount;
        DcaDetails[] memory dcaSchedules = s_dcaSchedules[user][token];
        for (uint256 i; i < dcaSchedules.length; ++i) {
            lockedTokenAmount += dcaSchedules[i].tokenBalance;
        }
        return tokenHandler.getAccruedInterest(user, lockedTokenAmount);
    }

    // function getTokenHandlerAddress(address token) external view returns (address) {
    //     return address(_handler(tokenAddress));
    // }
}
