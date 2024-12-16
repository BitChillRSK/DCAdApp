// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {TokenHandler} from "./TokenHandler.sol";
// import {IDocTokenHandlerDex} from "./interfaces/IDocTokenHandlerDex.sol";
// import {IkDocToken} from "./interfaces/IkDocToken.sol";
// import {IWRBTC} from "./interfaces/IWRBTC.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// // import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import {TransferHelper} from "./libraries/TransferHelper.sol";
// // import {ISwapRouter02} from "@uniswap/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol";
// import {ISwapRouter02} from "./interfaces/ISwapRouter02.sol";
// // import {IV3SwapRouter} from "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
// // import {IV3SwapRouter} from "./interfaces/IV3SwapRouter.sol";
// import {ICoinPairPrice} from "./interfaces/ICoinPairPrice.sol";

// /**
//  * @title DocTokenHandler
//  * @dev Implementation of the IDocTokenHandlerDex interface.
//  */
// contract DocTokenHandlerDex is TokenHandler, IDocTokenHandlerDex {
//     using SafeERC20 for IERC20;

//     //////////////////////
//     // State variables ///
//     //////////////////////
//     IERC20 public immutable i_docToken;
//     IkDocToken public immutable i_kDocToken;
//     IWRBTC public immutable i_wrBtcToken;
//     mapping(address user => uint256 balance) private s_kDocBalances;
//     mapping(address user => uint256 balance) private s_WrbtcBalances;
//     ISwapRouter02 public immutable i_swapRouter02;
//     ICoinPairPrice public immutable i_MocOracle;
//     uint256 constant EXCHANGE_RATE_DECIMALS = 1e18;
//     uint256 constant PRECISION = 1e18;
//     bytes public s_swapPath;

//     /**
//      * @notice the contract is ownable and after deployment its ownership shall be transferred to the wallet associated to the CRON job
//      * @notice the DCA contract inherits from OZ's Ownable, which is the secure, standard way to handle ownership
//      * @param dcaManagerAddress the address of the DCA Manager contract
//      * @param docTokenAddress the address of the Dollar On Chain token on the blockchain of deployment
//      * @param kDocTokenAddress the address of Tropykus' kDOC token contract
//      * @param minPurchaseAmount  the minimum amount of DOC for periodic purchases
//      * @param feeCollector the address of to which fees will sent on every purchase
//      * @param minFeeRate the lowest possible fee
//      * @param maxFeeRate the highest possible fee
//      * @param minAnnualAmount the annual amount below which max fee is applied
//      * @param maxAnnualAmount the annual amount above which min fee is applied
//      */
//     constructor(
//         address dcaManagerAddress,
//         address docTokenAddress, // TODO: modify this to passing the interface
//         address kDocTokenAddress, // TODO: modify this to passing the interface
//         IWRBTC wrBtcToken,
//         ISwapRouter02 swapRouter02,
//         address[] memory swapIntermediateTokens,
//         uint24[] memory swapPoolFeeRates,
//         ICoinPairPrice mocOracle,
//         uint256 minPurchaseAmount,
//         address feeCollector,
//         uint256 minFeeRate,
//         uint256 maxFeeRate,
//         uint256 minAnnualAmount,
//         uint256 maxAnnualAmount,
//         bool yieldsInterest
//     )
//         Ownable(msg.sender)
//         TokenHandler(
//             dcaManagerAddress,
//             docTokenAddress,
//             minPurchaseAmount,
//             feeCollector,
//             minFeeRate,
//             maxFeeRate,
//             minAnnualAmount,
//             maxAnnualAmount,
//             yieldsInterest
//         )
//     {
//         i_docToken = IERC20(docTokenAddress);
//         i_kDocToken = IkDocToken(kDocTokenAddress);
//         i_swapRouter02 = swapRouter02;
//         i_wrBtcToken = wrBtcToken;
//         i_MocOracle = mocOracle;
//         setPurchasePath(swapIntermediateTokens, swapPoolFeeRates);
//     }

//     /*//////////////////////////////////////////////////////////////
//                                FUNCTIONS
//     //////////////////////////////////////////////////////////////*/

//     /**
//      * @notice deposit the full token amount for DCA on the contract
//      * @param user: the address of the user making the deposit
//      * @param depositAmount: the amount to deposit
//      */
//     function depositToken(address user, uint256 depositAmount) public override onlyDcaManager {
//         super.depositToken(user, depositAmount);
//         if (i_docToken.allowance(address(this), address(i_kDocToken)) < depositAmount) {
//             bool approvalSuccess = i_docToken.approve(address(i_kDocToken), depositAmount);
//             if (!approvalSuccess) revert DocTokenHandlerDex__kDocApprovalFailed(user, depositAmount);
//         }
//         uint256 prevKdocBalance = i_kDocToken.balanceOf(address(this));
//         i_kDocToken.mint(depositAmount);
//         uint256 postKdocBalance = i_kDocToken.balanceOf(address(this));
//         s_kDocBalances[user] += postKdocBalance - prevKdocBalance;
//     }

//     /**
//      * @notice withdraw the token amount sending it back to the user's address
//      * @param user: the address of the user making the withdrawal
//      * @param withdrawalAmount: the amount to withdraw
//      */
//     function withdrawToken(address user, uint256 withdrawalAmount) public override onlyDcaManager {
//         uint256 docInTropykus = s_kDocBalances[user] * i_kDocToken.exchangeRateStored() / EXCHANGE_RATE_DECIMALS;
//         if (docInTropykus < withdrawalAmount) {
//             revert DocTokenHandlerDex__WithdrawalAmountExceedsKdocBalance(user, withdrawalAmount, docInTropykus);
//         }
//         _redeemDoc(user, withdrawalAmount);
//         super.withdrawToken(user, withdrawalAmount);
//     }

//     /**
//      * @param buyer: the user on behalf of which the contract is making the rBTC purchase
//      * @param purchaseAmount: the amount to spend on rBTC
//      * @param purchasePeriod: the period between purchases
//      * @notice this function will be called periodically through a CRON job running on a web server
//      * @notice it is checked that the purchase period has elapsed, as added security on top of onlyOwner modifier
//      */
//     function buyRbtc(address buyer, bytes32 scheduleId, uint256 purchaseAmount, uint256 purchasePeriod)
//         external
//         override
//         onlyDcaManager
//     {
//         // Redeem DOC (repaying kDOC)
//         _redeemDoc(buyer, purchaseAmount);

//         // Charge fee
//         uint256 fee = _calculateFee(purchaseAmount, purchasePeriod);
//         uint256 netPurchaseAmount = purchaseAmount - fee;
//         _transferFee(fee);

//         // Swap DOC for WRBTC
//         uint256 wrBtcPurchased = _swapDocForWrbtc(netPurchaseAmount);

//         if (wrBtcPurchased > 0) {
//             s_usersAccumulatedRbtc[buyer] += wrBtcPurchased;
//             emit TokenHandler__RbtcBought(buyer, address(i_docToken), wrBtcPurchased, scheduleId, netPurchaseAmount);
//         } else {
//             revert TokenHandler__RbtcPurchaseFailed(buyer, address(i_docToken));
//         }
//     }

//     function batchBuyRbtc(
//         address[] memory buyers,
//         bytes32[] memory scheduleIds,
//         uint256[] memory purchaseAmounts,
//         uint256[] memory purchasePeriods
//     ) external override onlyDcaManager {
//         uint256 numOfPurchases = buyers.length;

//         // Calculate net amounts
//         (uint256 aggregatedFee, uint256[] memory netDocAmountsToSpend, uint256 totalDocAmountToSpend) =
//             _calculateFeeAndNetAmounts(purchaseAmounts, purchasePeriods);

//         // Redeem DOC (and repay kDOC)
//         _batchRedeemDoc(buyers, purchaseAmounts, totalDocAmountToSpend + aggregatedFee); // total DOC to redeem by repaying kDOC in order to spend it to redeem rBTC is totalDocAmountToSpend + aggregatedFee

//         // Charge fees
//         _transferFee(aggregatedFee);

//         // Swap DOC for wrBTC
//         uint256 wrBtcPurchased = _swapDocForWrbtc(totalDocAmountToSpend);

//         if (wrBtcPurchased > 0) {
//             for (uint256 i; i < numOfPurchases; ++i) {
//                 uint256 usersPurchasedWrbtc = wrBtcPurchased * netDocAmountsToSpend[i] / totalDocAmountToSpend;
//                 s_usersAccumulatedRbtc[buyers[i]] += usersPurchasedWrbtc;
//                 emit TokenHandler__RbtcBought(
//                     buyers[i], address(i_docToken), usersPurchasedWrbtc, scheduleIds[i], netDocAmountsToSpend[i]
//                 );
//             }
//             emit TokenHandler__SuccessfulRbtcBatchPurchase(address(i_docToken), wrBtcPurchased, totalDocAmountToSpend);
//         } else {
//             revert TokenHandler__RbtcBatchPurchaseFailed(address(i_docToken));
//         }
//     }

//     function getUsersKdocBalance(address user) external view override returns (uint256) {
//         return s_kDocBalances[user];
//     }

//     function withdrawInterest(address user, uint256 docLockedInDcaSchedules) external override onlyDcaManager {
//         uint256 totalDocInDeposit = s_kDocBalances[user] * EXCHANGE_RATE_DECIMALS / i_kDocToken.exchangeRateStored();
//         uint256 docInterestAmount = totalDocInDeposit - docLockedInDcaSchedules;
//         _redeemDoc(user, docInterestAmount);
//         i_docToken.safeTransfer(user, docInterestAmount);
//     }

//     function getAccruedInterest(address user, uint256 docLockedInDcaSchedules)
//         external
//         view
//         override
//         onlyDcaManager
//         returns (uint256 docInterestAmount)
//     {
//         uint256 totalDocInLending = s_kDocBalances[user] * EXCHANGE_RATE_DECIMALS / i_kDocToken.exchangeRateStored();
//         docInterestAmount = totalDocInLending - docLockedInDcaSchedules;
//     }

//     /**
//      * @notice the user can at any time withdraw the rBTC that has been accumulated through periodical purchases
//      * @notice anyone can pay for the transaction to have the rBTC sent to the user
//      */
//     function withdrawAccumulatedRbtc(address user) external override {
//         uint256 rbtcBalance = s_usersAccumulatedRbtc[user];
//         if (rbtcBalance == 0) revert TokenHandler__NoAccumulatedRbtcToWithdraw();

//         s_usersAccumulatedRbtc[user] = 0;

//         // Unwrap rBTC
//         i_wrBtcToken.withdraw(rbtcBalance);

//         // Transfer RBTC from this contract back to the user
//         (bool sent,) = user.call{value: rbtcBalance}("");
//         if (!sent) revert TokenHandler__rBtcWithdrawalFailed();
//         emit TokenHandler__rBtcWithdrawn(user, rbtcBalance);
//     }

//     /**
//      * @notice Sets a new swap path.
//      *  @param intermediateTokens The array of intermediate token addresses in the path.
//      * @param poolFeeRates The array of pool fees for each swap step.
//      */
//     function setPurchasePath(address[] memory intermediateTokens, uint24[] memory poolFeeRates)
//         public
//         override
//         onlyOwner /* TODO: set another role for access control? */
//     {
//         if (poolFeeRates.length != intermediateTokens.length + 1) {
//             revert DocTokenHandlerDex__WrongNumberOfTokensOrFeeRates(intermediateTokens.length, poolFeeRates.length);
//         }

//         bytes memory newPath = abi.encodePacked(address(i_docToken));
//         for (uint256 i = 0; i < intermediateTokens.length; i++) {
//             newPath = abi.encodePacked(newPath, poolFeeRates[i], intermediateTokens[i]);
//         }

//         newPath = abi.encodePacked(newPath, poolFeeRates[poolFeeRates.length - 1], address(i_wrBtcToken));

//         s_swapPath = newPath;
//         emit DocTokenHandlerDex_NewPathSet(intermediateTokens, poolFeeRates, s_swapPath);
//     }

//     /*//////////////////////////////////////////////////////////////
//                            INTERNAL FUNCTIONS
//     //////////////////////////////////////////////////////////////*/
//     function _calculateFeeAndNetAmounts(uint256[] memory purchaseAmounts, uint256[] memory purchasePeriods)
//         internal
//         view
//         returns (uint256, uint256[] memory, uint256)
//     {
//         uint256 fee;
//         uint256 aggregatedFee;
//         uint256[] memory netDocAmountsToSpend = new uint256[](purchaseAmounts.length);
//         uint256 totalDocAmountToSpend;
//         for (uint256 i; i < purchaseAmounts.length; ++i) {
//             fee = _calculateFee(purchaseAmounts[i], purchasePeriods[i]);
//             aggregatedFee += fee;
//             netDocAmountsToSpend[i] = purchaseAmounts[i] - fee;
//             totalDocAmountToSpend += netDocAmountsToSpend[i];
//         }
//         return (aggregatedFee, netDocAmountsToSpend, totalDocAmountToSpend);
//     }

//     /**
//      * @param docAmountToSpend the amount of DOC to swap for BTC
//      */
//     function _swapDocForWrbtc(uint256 docAmountToSpend) internal returns (uint256 amountOut) {
//         // Approve the router to spend DOC.
//         TransferHelper.safeApprove(address(i_docToken), address(i_swapRouter02), docAmountToSpend);

//         // Set up the swap parameters
//         ISwapRouter02.ExactInputParams memory params = ISwapRouter02.ExactInputParams({
//             // IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
//             path: s_swapPath,
//             recipient: address(this),
//             amountIn: docAmountToSpend,
//             amountOutMinimum: _getAmountOutMinimum(docAmountToSpend)
//         });

//         amountOut = i_swapRouter02.exactInput(params);
//         // amountOut = IV3SwapRouter(address(i_swapRouter02)).exactInput(params);
//     }

//     function _getAmountOutMinimum(uint256 docAmountToSpend) internal view returns (uint256 minimumRbtcAmount) {
//         minimumRbtcAmount = (docAmountToSpend * PRECISION * 99) / (100 * i_MocOracle.getPrice()); // TODO: DOUBLE-CHECK MATH!!!
//     }

//     function _redeemDoc(address user, uint256 docToRedeem) internal {
//         (, uint256 underlyingAmount,,) = i_kDocToken.getSupplierSnapshotStored(address(this)); // esto devuelve el DOC retirable por la dirección de nuestro contrato en la última actualización de mercado
//         if (docToRedeem > underlyingAmount) revert DocTokenHandlerDex__DocRedeemAmountExceedsBalance(docToRedeem);
//         uint256 exchangeRate = i_kDocToken.exchangeRateStored(); // esto devuelve la tasa de cambio
//         uint256 usersKdocBalance = s_kDocBalances[user];
//         uint256 kDocToRepay = docToRedeem * exchangeRate / EXCHANGE_RATE_DECIMALS;
//         if (kDocToRepay > usersKdocBalance) {
//             revert DocTokenHandlerDex__KdocToRepayExceedsUsersBalance(
//                 user, docToRedeem * exchangeRate, usersKdocBalance
//             );
//         }
//         s_kDocBalances[user] -= kDocToRepay;
//         i_kDocToken.redeemUnderlying(docToRedeem);
//         emit DocTokenHandlerDex__SuccessfulDocRedemption(user, docToRedeem, kDocToRepay);
//     }

//     function _batchRedeemDoc(address[] memory users, uint256[] memory purchaseAmounts, uint256 totalDocToRedeem)
//         internal
//     {
//         // @notice here we don't follow CEI, but this function is protected by an onlyDcaManager modifier
//         uint256 kDocBalancePrev = i_kDocToken.balanceOf(address(this));
//         i_kDocToken.redeemUnderlying(totalDocToRedeem);
//         uint256 kDocBalancePost = i_kDocToken.balanceOf(address(this));

//         if (kDocBalancePrev - kDocBalancePost > 0) {
//             uint256 totalKdocRepayed = kDocBalancePrev - kDocBalancePost;
//             uint256 numOfPurchases = users.length;
//             for (uint256 i; i < numOfPurchases; ++i) {
//                 // @notice the amount of kDOC each user repays is proportional to the ratio of that user's DOC getting redeemed over the total DOC getting redeemed
//                 uint256 usersRepayedKdoc = totalKdocRepayed * purchaseAmounts[i] / totalDocToRedeem;
//                 s_kDocBalances[users[i]] -= usersRepayedKdoc;
//                 emit DocTokenHandlerDex__DocRedeemedKdocRepayed(users[i], purchaseAmounts[i], usersRepayedKdoc);
//             }
//             emit DocTokenHandlerDex__SuccessfulBatchDocRedemption(totalDocToRedeem, totalKdocRepayed);
//         } else {
//             revert DocTokenHandlerDex__BatchRedeemDocFailed();
//         }
//     }
// }
