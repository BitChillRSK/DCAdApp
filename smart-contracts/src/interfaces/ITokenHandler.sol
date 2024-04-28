// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITokenHandler
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the TokenHandler contract.
 */
interface ITokenHandler {
    ////////////////////////
    // Type declarations ///
    ////////////////////////
    struct DcaDetails {
        uint256 docBalance; // DOC balance deposited by the user
        uint256 docPurchaseAmount; // DOC to spend periodically on rBTC
        uint256 purchasePeriod; // Time between purchases in seconds
        uint256 lastPurchaseTimestamp; // Timestamp of the latest purchase
        uint256 rbtcBalance; // User's accumulated RBTC balance
    }

    //////////////////////
    // Events ////////////
    //////////////////////
    event DocDeposited(address indexed user, uint256 amount);
    event DocWithdrawn(address indexed user, uint256 amount);
    event PurchaseAmountSet(address indexed user, uint256 purchaseAmount);
    event PurchasePeriodSet(address indexed user, uint256 purchasePeriod);
    event newDcaScheduleCreated(
        address indexed user, uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod
    );
    event rBtcWithdrawn(address indexed user, uint256 amount);

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
    error RbtcDca__CannotWithdrawRbtcBeforeBuying();
    error RbtcDca__rBtcWithdrawalFailed();

    ///////////////////////////////
    // External functions /////////
    ///////////////////////////////

    /**
     * @notice deposit the full DOC amount for DCA on the contract
     * @param depositAmount: the amount of DOC to deposit
     */
    function depositDOC(uint256 depositAmount) external;

    /**
     * @notice withdraw some or all of the DOC previously deposited
     * @param withdrawalAmount: the amount of DOC to withdraw
     */
    function withdrawDOC(uint256 withdrawalAmount) external;

    /**
     * @notice the user can at any time withdraw the rBTC that has been accumulated through periodical purchases
     */
    function withdrawAccumulatedRbtc() external;

    function mintKdoc(uint256 depositAmount) external;

    function redeemKdoc(uint256 withdrawalAmount) external;
}
