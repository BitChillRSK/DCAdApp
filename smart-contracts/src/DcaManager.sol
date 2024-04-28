// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDocToken} from "./interfaces/IDocToken.sol";
import {IkDocToken} from "./interfaces/IkDocToken.sol";
import {IMocProxy} from "./interfaces/IMocProxy.sol";

/**
 * @title DCA Manager
 * @author BitChill team: Antonio María Rodríguez-Ynyesto Sánchez
 * @notice This contract will be used to save and edit the users' DCA strategies
 * @custom:unaudited This is an unaudited contract
 */
contract DcaManager is Ownable {
    //////////////////////
    // Events ////////////
    //////////////////////
    event DocDeposited(address indexed user, uint256 amount);
    event DocWithdrawn(address indexed user, uint256 amount);
    event RbtcBought(address indexed user, uint256 docAmount, uint256 rbtcAmount);
    event rBtcWithdrawn(address indexed user, uint256 rbtcAmount);
    event PurchaseAmountSet(address indexed user, uint256 purchaseAmount);
    event PurchasePeriodSet(address indexed user, uint256 purchasePeriod);
    event newDcaScheduleCreated(
        address indexed user, uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod
    );

    //////////////////////
    // Errors ////////////
    //////////////////////
    error RbtcDca__DepositAmountMustBeGreaterThanZero();
    error RbtcDca__DocWithdrawalAmountMustBeGreaterThanZero();
    error RbtcDca__DocWithdrawalAmountExceedsBalance();
    error RbtcDca__NotEnoughDocAllowanceForDcaContract();
    error RbtcDca__DocDepositFailed();
    error RbtcDca__DocWithdrawalFailed();
    error RbtcDca__PurchaseAmountMustBeGreaterThanZero();
    error RbtcDca__PurchasePeriodMustBeGreaterThanZero();
    error RbtcDca__PurchaseAmountMustBeLowerThanHalfOfBalance();
    error RbtcDca__RedeemDocRequestFailed();
    error RbtcDca__RedeemFreeDocFailed();
    error RbtcDca__CannotWithdrawRbtcBeforeBuying();
    error RbtcDca__rBtcWithdrawalFailed();
    error RbtcDca__OnlyMocProxyCanSendRbtcToDcaContract();
    error RbtcDca__CannotBuyIfPurchasePeriodHasNotElapsed();
    error RbtcDca__CannotDepositInTropykusMoreThanBalance();
    error RbtcDca__DocApprovalForKdocContractFailed();
    error RbtcDca__TropykusDepositFailed();

    //////////////////////
    // Functions /////////
    //////////////////////

    /**
     * @notice the contract is ownable and after deployment its ownership shall be transferred to the wallet associated to the CRON job
     * @notice the DCA contract inherits from OZ's Ownable, which is the secure, standard way to handle ownership
     * @param docTokenAddress: the address of the Dollar On Chain token on the blockchain of deployment
     * @param mocProxyAddress: the address of the MoC proxy contract on the blockchain of deployment
     */
    constructor(address docTokenAddress, address mocProxyAddress) Ownable(msg.sender) {
        i_docToken = IDocToken(docTokenAddress);
        i_mocProxy = IMocProxy(mocProxyAddress);
        // i_kdocToken = IkDocToken(kdocTokenAddress);
    }

    /**
     * @param purchaseAmount: the amount of DOC to swap periodically for rBTC
     * @notice the amount cannot be greater than or equal to half of the deposited amount
     */
    function setPurchaseAmount(uint256 purchaseAmount) external {
        _setPurchaseAmount(purchaseAmount);
        emit PurchaseAmountSet(msg.sender, purchaseAmount);
    }

    /**
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     * @notice the period
     */
    function setPurchasePeriod(uint256 purchasePeriod) external {
        _setPurchasePeriod(purchasePeriod);
        emit PurchasePeriodSet(msg.sender, purchasePeriod);
    }

    /**
     * @notice deposit the full DOC amount for DCA on the contract, set the period and the amount for purchases
     * @param depositAmount: the amount of DOC to deposit
     * @param purchaseAmount: the amount of DOC to swap periodically for rBTC
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     */
    function createDcaSchedule(uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod) external {
        _depositDOC(depositAmount);
        _setPurchaseAmount(purchaseAmount);
        _setPurchasePeriod(purchasePeriod);
        emit newDcaScheduleCreated(msg.sender, depositAmount, purchaseAmount, purchasePeriod);
    }

    ///////////////////////////////
    // Internal functions /////////
    ///////////////////////////////

    /**
     * @param purchaseAmount: the amount of DOC to swap periodically for rBTC
     * @notice the amount cannot be greater than or equal to half of the deposited amount
     */
    function _setPurchaseAmount(uint256 purchaseAmount) internal {
        if (purchaseAmount <= 0) revert RbtcDca__PurchaseAmountMustBeGreaterThanZero();
        if (purchaseAmount > s_dcaDetails[msg.sender].docBalance / 2) {
            revert RbtcDca__PurchaseAmountMustBeLowerThanHalfOfBalance();
        } //At least two DCA purchases
        s_dcaDetails[msg.sender].docPurchaseAmount = purchaseAmount;
    }

    /**
     * @param purchasePeriod: the time (in seconds) between rBTC purchases for each user
     * @notice the period
     */
    function _setPurchasePeriod(uint256 purchasePeriod) internal {
        if (purchasePeriod <= 0) revert RbtcDca__PurchasePeriodMustBeGreaterThanZero();
        s_dcaDetails[msg.sender].purchasePeriod = purchasePeriod;
    }

    //////////////////////
    // Getter functions //
    //////////////////////
    function getMyDcaDetails() external view returns (DcaDetails memory) {
        return s_dcaDetails[msg.sender];
    }

    function getDocBalance() external view returns (uint256) {
        return s_dcaDetails[msg.sender].docBalance;
    }

    function getRbtcBalance() external view returns (uint256) {
        return s_dcaDetails[msg.sender].rbtcBalance;
    }

    function getPurchaseAmount() external view returns (uint256) {
        return s_dcaDetails[msg.sender].docPurchaseAmount;
    }

    function getPurchasePeriod() external view returns (uint256) {
        return s_dcaDetails[msg.sender].purchasePeriod;
    }

    function ownerGetUsersDcaDetails(address user) external view onlyOwner returns (DcaDetails memory) {
        return s_dcaDetails[user];
    }

    function getUsers() external view onlyOwner returns (address[] memory) {
        return s_users;
    }

    function getTotalNumberOfDeposits() external view returns (uint256) {
        return s_users.length;
    }
}
