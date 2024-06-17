// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IDocTokenHandler
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the TokenHandler contract.
 */
interface IDocTokenHandler {
    //////////////////////
    // Events ////////////
    //////////////////////
    event DocTokenHandler__SuccessfulDocRedemption(address indexed user, uint256 indexed docRedeemed, uint256 indexed kDocRepayed);
    event DocTokenHandler__SuccessfulBatchDocRedemption(uint256 indexed docRedeemed, uint256 indexed kDocRepayed);
    event DocTokenHandler__DocRedeemedKdocRepayed(address indexed user, uint256 docRedeemed, uint256 indexed kDocRepayed);

    //////////////////////
    // Errors ////////////
    //////////////////////
    error DocTokenHandler__RedeemDocRequestFailed();
    error DocTokenHandler__RedeemFreeDocFailed();
    error DocTokenHandler__RedeemAmountExceedsBalance(uint256 redeemAmount);
    error DocTokenHandler__InterestWithdrawalFailed(address user, uint256 interestAmount);
    error DocTokenHandler__kDocApprovalFailed(address user, uint256 depositAmount);
    error DocTokenHandler__WithdrawalAmountExceedsKdocBalance(address user, uint256 withdrawalAmount, uint256 balance);
    error DocTokenHandler__KdocToRepayExceedsUsersBalance(address user, uint256 kDocAmountToRepay, uint256 kDocUserbalance);
    error DocTokenHandler__BatchRedeemDocFailed();
    
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice deposit the full token amount for DCA on the contract
     * @param user: the address of the user making the deposit
     * @param depositAmount: the amount to deposit
     */
    // function depositDocAndLend(address user, uint256 depositAmount) external;
}
