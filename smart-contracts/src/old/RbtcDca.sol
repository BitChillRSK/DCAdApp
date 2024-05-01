// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

//////////////////////
// Interfaces ////////
//////////////////////
interface DocTokenContract {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface MocProxyContract {
    function redeemDocRequest(uint256 docAmount) external;
    function redeemFreeDoc(uint256 docAmount) external;
}

/**
 * @title DCA Contract
 * @author Antonio María Rodríguez-Ynyesto Sánchez
 * @notice The DOC deposited in this contract will be used to make periodical rBTC purchases
 * @custom:unaudited This is an unaudited contract
 */
contract RbtcDca is Ownable {
    ////////////////////////
    // Type declarations ///
    ////////////////////////
    struct DcaDetails {
        uint256 docBalance; // DOC balance deposited by the user
        uint256 docPurchaseAmount; // DOC to spend periodically on rBTC
        uint256 purchasePeriod; // Time between purchases
        uint256 lastPurchaseTimestamp; // Timestamp of the latest purchase
        uint256 rbtcBalance; // User's accumulated RBTC balance
    }

    //////////////////////
    // State variables ///
    //////////////////////
    DocTokenContract immutable i_docTokenContract;
    MocProxyContract immutable i_mocProxyContract;
    mapping(address user => DcaDetails usersDcaDetails) private s_dcaDetails;
    address[] private s_users; // Users that have deposited DOC in the DCA contract

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
    error RbtcDca__OnlyMocProxyContractCanSendRbtcToDcaContract();
    error RbtcDca__CannotBuyIfPurchasePeriodHasNotElapsed();

    //////////////////////
    // Modifiers /////////
    //////////////////////
    modifier onlyMocProxy() {
        if (msg.sender != address(i_mocProxyContract)) revert RbtcDca__OnlyMocProxyContractCanSendRbtcToDcaContract();
        _;
    }

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
        i_docTokenContract = DocTokenContract(docTokenAddress);
        i_mocProxyContract = MocProxyContract(mocProxyAddress);
    }

    receive() external payable onlyMocProxy {}

    ///////////////////////////////
    // External functions /////////
    ///////////////////////////////

    /**
     * @notice deposit the full DOC amount for DCA on the contract
     * @param depositAmount: the amount of DOC to deposit
     */
    function depositDOC(uint256 depositAmount) external {
        _depositDOC(depositAmount);
        emit DocDeposited(msg.sender, depositAmount);
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

    /**
     * @notice withdraw some or all of the DOC previously deposited
     * @param withdrawalAmount: the amount of DOC to withdraw
     */
    function withdrawDOC(uint256 withdrawalAmount) external {
        if (withdrawalAmount <= 0) revert RbtcDca__DocWithdrawalAmountMustBeGreaterThanZero();
        if (withdrawalAmount > s_dcaDetails[msg.sender].docBalance) revert RbtcDca__DocWithdrawalAmountExceedsBalance();

        // Update user's DOC balance in the mapping
        s_dcaDetails[msg.sender].docBalance -= withdrawalAmount;

        // Transfer DOC from this contract back to the user
        bool withdrawalSuccess = i_docTokenContract.transfer(msg.sender, withdrawalAmount);
        if (!withdrawalSuccess) revert RbtcDca__DocWithdrawalFailed();

        emit DocWithdrawn(msg.sender, withdrawalAmount);
    }

    /**
     * @param buyer: the user on behalf of which the contract is making the rBTC purchase
     * @notice this function will be called periodically through a CRON job running on a web server
     * @notice it is checked that the purchase period has elapsed, as added security on top of onlyOwner modifier
     */
    function buyRbtc(address buyer) external onlyOwner {
        // If the user made their first purchase, check that period has elapsed before making a new purchase
        if (s_dcaDetails[buyer].rbtcBalance > 0) {
            if (block.timestamp - s_dcaDetails[buyer].lastPurchaseTimestamp < s_dcaDetails[buyer].purchasePeriod) {
                revert RbtcDca__CannotBuyIfPurchasePeriodHasNotElapsed();
            }
        }

        s_dcaDetails[buyer].docBalance -= s_dcaDetails[buyer].docPurchaseAmount;
        s_dcaDetails[buyer].lastPurchaseTimestamp = block.timestamp;

        // Redeem DOC for rBTC
        (bool success,) = address(i_mocProxyContract).call(
            abi.encodeWithSignature("redeemDocRequest(uint256)", s_dcaDetails[buyer].docPurchaseAmount)
        );
        if (!success) revert RbtcDca__RedeemDocRequestFailed();
        // Now that redeemDocRequest has completed, proceed to redeemFreeDoc
        uint256 balancePrev = address(this).balance;
        (success,) = address(i_mocProxyContract).call(
            abi.encodeWithSignature("redeemFreeDoc(uint256)", s_dcaDetails[buyer].docPurchaseAmount)
        );
        if (!success) revert RbtcDca__RedeemFreeDocFailed();
        uint256 balancePost = address(this).balance;

        s_dcaDetails[buyer].rbtcBalance += (balancePost - balancePrev);

        emit RbtcBought(buyer, s_dcaDetails[buyer].docPurchaseAmount, balancePost - balancePrev);
    }

    /**
     * @notice the user can at any time withdraw the rBTC that has been accumulated through periodical purchases
     */
    function withdrawAccumulatedRbtc() external {
        address user = msg.sender;
        uint256 rbtcBalance = s_dcaDetails[user].rbtcBalance;
        if (rbtcBalance == 0) revert RbtcDca__CannotWithdrawRbtcBeforeBuying();

        s_dcaDetails[user].rbtcBalance = 0;
        // Transfer RBTC from this contract back to the user
        (bool sent,) = user.call{value: rbtcBalance}("");
        if (!sent) revert RbtcDca__rBtcWithdrawalFailed();
        emit rBtcWithdrawn(user, rbtcBalance);
    }

    ///////////////////////////////
    // Internal functions /////////
    ///////////////////////////////

    /**
     * @notice deposit the full DOC amount for DCA on the contract
     * @param depositAmount: the amount of DOC to deposit
     */
    function _depositDOC(uint256 depositAmount) internal {
        if (depositAmount <= 0) revert RbtcDca__DepositAmountMustBeGreaterThanZero();

        // Transfer DOC from the user to this contract, user must have called the DOC contract's
        // approve function with this contract's address and the amount approved
        if (i_docTokenContract.allowance(msg.sender, address(this)) < depositAmount) {
            revert RbtcDca__NotEnoughDocAllowanceForDcaContract();
        }

        uint256 prevDocBalance = s_dcaDetails[msg.sender].docBalance;

        // Update user's DOC balance in the mapping
        s_dcaDetails[msg.sender].docBalance += depositAmount;

        bool depositSuccess = i_docTokenContract.transferFrom(msg.sender, address(this), depositAmount);
        if (!depositSuccess) revert RbtcDca__DocDepositFailed();

        // Add user to users array
        /**
         * @notice every time a user who ran out of deposited DOC makes a new deposit they will be added to the users array, which is filtered in the dApp's back end.
         * Dynamic arrays have 2^256 positions, so repeated addresses are not an issue.
         */
        if (prevDocBalance == 0) s_users.push(msg.sender);
    }

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
