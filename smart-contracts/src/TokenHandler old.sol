// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// import {IDocToken} from "./interfaces/IDocToken.sol";
// import {IkDocToken} from "./interfaces/IkDocToken.sol";
// import {ITokenHandler} from "./interfaces/ITokenHandler.sol";
// // import {DcaManager} from "./DcaManager.sol";

// contract TokenHandler is ITokenHandler {
//     //////////////////////
//     // State variables ///
//     //////////////////////
//     IDocToken immutable i_docToken;
//     IkDocToken immutable i_kdocToken;
//     mapping(address user => DcaDetails usersDcaDetails) private s_dcaDetails;
//     address[] private s_users; // Users that have deposited DOC in the DCA contract
//     // DcaManager immutable i_dcaManager;

//     constructor(address docTokenAddress, address kdocTokenAddress /*, address dcaManagerAddress  */ ) {
//         i_kdocToken = IkDocToken(kdocTokenAddress);
//         i_docToken = IDocToken(docTokenAddress);
//         // i_dcaManager = DcaManager(dcaManagerAddress);
//     }

//     ///////////////////////////////
//     // External functions /////////
//     ///////////////////////////////

//     /**
//      * @notice deposit the full DOC amount for DCA on the contract
//      * @param depositAmount: the amount of DOC to deposit
//      */
//     function depositDOC(uint256 depositAmount) external {
//         _depositDOC(depositAmount);
//         emit DocDeposited(msg.sender, depositAmount);
//     }

//     /**
//      * @notice withdraw some or all of the DOC previously deposited
//      * @param withdrawalAmount: the amount of DOC to withdraw
//      */
//     function withdrawDOC(uint256 withdrawalAmount) external {
//         if (withdrawalAmount <= 0) revert RbtcDca__DocWithdrawalAmountMustBeGreaterThanZero();
//         if (withdrawalAmount > s_dcaDetails[msg.sender].docBalance) revert RbtcDca__DocWithdrawalAmountExceedsBalance();

//         // Update user's DOC balance in the mapping
//         s_dcaDetails[msg.sender].docBalance -= withdrawalAmount;

//         // Transfer DOC from this contract back to the user
//         bool withdrawalSuccess = i_docToken.transfer(msg.sender, withdrawalAmount);
//         if (!withdrawalSuccess) revert RbtcDca__DocWithdrawalFailed();

//         emit DocWithdrawn(msg.sender, withdrawalAmount);
//     }

//     /**
//      * @notice the user can at any time withdraw the rBTC that has been accumulated through periodical purchases
//      */
//     function withdrawAccumulatedRbtc() external {
//         address user = msg.sender;
//         uint256 rbtcBalance = s_dcaDetails[user].rbtcBalance;
//         if (rbtcBalance == 0) revert RbtcDca__CannotWithdrawRbtcBeforeBuying();

//         s_dcaDetails[user].rbtcBalance = 0;
//         // Transfer RBTC from this contract back to the user
//         (bool sent,) = user.call{value: rbtcBalance}("");
//         if (!sent) revert RbtcDca__rBtcWithdrawalFailed();
//         emit rBtcWithdrawn(user, rbtcBalance);
//     }

//     function mintKdoc(uint256 depositAmount) external {
//         bool depositSuccess = i_docToken.transferFrom(msg.sender, address(this), depositAmount);
//         // bool depositSuccess = i_docToken.transferFrom(address(i_dcaManager), address(this), depositAmount);
//         require(depositSuccess, "Deposit failed");
//         bool approvalSuccess = i_docToken.approve(address(i_kdocToken), depositAmount);
//         require(approvalSuccess, "Approval failed");
//         i_kdocToken.mint(depositAmount);
//     }

//     function redeemKdoc(uint256 withdrawalAmount) external {
//         i_kdocToken.redeemUnderlying(withdrawalAmount);
//         bool withdrawalSuccess = i_docToken.transfer(msg.sender, withdrawalAmount);
//         require(withdrawalSuccess);
//     }

//     ///////////////////////////////
//     // Internal functions /////////
//     ///////////////////////////////

//     /**
//      * @notice deposit the full DOC amount for DCA on the contract
//      * @param depositAmount: the amount of DOC to deposit
//      */
//     function _depositDOC(uint256 depositAmount) internal {
//         if (depositAmount <= 0) revert RbtcDca__DepositAmountMustBeGreaterThanZero();

//         // Transfer DOC from the user to this contract, user must have called the DOC contract's
//         // approve function with this contract's address and the amount approved
//         if (i_docToken.allowance(msg.sender, address(this)) < depositAmount) {
//             revert RbtcDca__NotEnoughDocAllowanceForDcaContract();
//         }

//         uint256 prevDocBalance = s_dcaDetails[msg.sender].docBalance;

//         // Update user's DOC balance in the mapping
//         s_dcaDetails[msg.sender].docBalance += depositAmount;

//         bool depositSuccess = i_docToken.transferFrom(msg.sender, address(this), depositAmount);
//         if (!depositSuccess) revert RbtcDca__DocDepositFailed();

//         // Add user to users array
//         /**
//          * @notice every time a user who ran out of deposited DOC makes a new deposit they will be added to the users array, which is filtered in the dApp's back end.
//          * Dynamic arrays have 2^256 positions, so repeated addresses are not an issue.
//          */
//         if (prevDocBalance == 0) s_users.push(msg.sender);
//     }

//     ////////////////////////////////
//     /// Tropykus Interactions //////
//     ////////////////////////////////

//     // function _mintKdoc(address user, uint256 docToDeposit) internal {
//     //     if(docToDeposit > s_dcaDetails[user].docBalance) revert RbtcDca__CannotDepositInTropykusMoreThanBalance();
//     //     bool approvalSuccess = i_docToken.approve(address(i_kdocToken), docToDeposit);
//     //     if(!approvalSuccess) revert RbtcDca__DocApprovalForKdocContractFailed();

//     //     // Update user's DOC balance in the mapping
//     //     s_dcaDetails[user].docBalance -= docToDeposit;

//     //     // Mint kDOC by depositing DOC
//     //     uint256 errorCode = i_kdocToken.mint(docToDeposit);
//     //     if(errorCode > 0) revert RbtcDca__TropykusDepositFailed();
//     // }

//     // function _redeemKdoc(address user, uint256 docToWithdraw) internal {
//     //     i_kdocToken.redeemUnderlying(docToWithdraw);

//     //     // Update user's DOC balance in the mapping
//     //     s_dcaDetails[user].docBalance += docToWithdraw;

//     //     require(withdrawalSuccess);
//     // }
// }
