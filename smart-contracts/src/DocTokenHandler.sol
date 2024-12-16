// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {TokenHandler} from "./TokenHandler.sol";
import {IDocTokenHandler} from "./interfaces/IDocTokenHandler.sol";
import {IkDocToken} from "./interfaces/IkDocToken.sol";
import {IMocProxy} from "./interfaces/IMocProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DocTokenHandler
 * @dev Implementation of the IDocTokenHandler interface.
 */
contract DocTokenHandler is TokenHandler, IDocTokenHandler {
    using SafeERC20 for IERC20;

    //////////////////////
    // State variables ///
    //////////////////////
    IMocProxy public immutable i_mocProxy;
    IERC20 public immutable i_docToken;
    IkDocToken public immutable i_kDocToken;
    mapping(address user => uint256 balance) private s_kDocBalances;
    uint256 constant EXCHANGE_RATE_DECIMALS = 1e18;

    /**
     * @notice the contract is ownable and after deployment its ownership shall be transferred to the wallet associated to the CRON job
     * @notice the DCA contract inherits from OZ's Ownable, which is the secure, standard way to handle ownership
     * @param dcaManagerAddress the address of the DCA Manager contract
     * @param docTokenAddress the address of the Dollar On Chain token on the blockchain of deployment
     * @param kDocTokenAddress the address of Tropykus' kDOC token contract
     * @param minPurchaseAmount  the minimum amount of DOC for periodic purchases
     * @param mocProxyAddress the address of the MoC proxy contract on the blockchain of deployment
     * @param feeCollector the address of to which fees will sent on every purchase
     * @param minFeeRate the lowest possible fee
     * @param maxFeeRate the highest possible fee
     * @param minAnnualAmount the annual amount below which max fee is applied
     * @param maxAnnualAmount the annual amount above which min fee is applied
     */
    constructor(
        address dcaManagerAddress,
        address docTokenAddress,
        address kDocTokenAddress,
        uint256 minPurchaseAmount,
        address feeCollector,
        address mocProxyAddress,
        uint256 minFeeRate,
        uint256 maxFeeRate,
        uint256 minAnnualAmount,
        uint256 maxAnnualAmount,
        bool yieldsInterest
    )
        TokenHandler(
            dcaManagerAddress,
            docTokenAddress,
            minPurchaseAmount,
            feeCollector,
            minFeeRate,
            maxFeeRate,
            minAnnualAmount,
            maxAnnualAmount,
            yieldsInterest
        )
    {
        i_docToken = IERC20(docTokenAddress);
        i_kDocToken = IkDocToken(kDocTokenAddress);
        i_mocProxy = IMocProxy(mocProxyAddress);
    }

    /**
     * @notice deposit the full token amount for DCA on the contract
     * @param user: the address of the user making the deposit
     * @param depositAmount: the amount to deposit
     */
    function depositToken(address user, uint256 depositAmount) public override onlyDcaManager {
        super.depositToken(user, depositAmount);
        if (i_docToken.allowance(address(this), address(i_kDocToken)) < depositAmount) {
            bool approvalSuccess = i_docToken.approve(address(i_kDocToken), depositAmount);
            if (!approvalSuccess) revert DocTokenHandler__kDocApprovalFailed(user, depositAmount);
        }
        uint256 prevKdocBalance = i_kDocToken.balanceOf(address(this));
        i_kDocToken.mint(depositAmount);
        uint256 postKdocBalance = i_kDocToken.balanceOf(address(this));
        s_kDocBalances[user] += postKdocBalance - prevKdocBalance;
    }

    /**
     * @notice withdraw the token amount sending it back to the user's address
     * @param user: the address of the user making the withdrawal
     * @param withdrawalAmount: the amount to withdraw
     */
    function withdrawToken(address user, uint256 withdrawalAmount) public override onlyDcaManager {
        uint256 docInTropykus = _kdocToDoc(s_kDocBalances[user], i_kDocToken.exchangeRateStored());
        if (docInTropykus < withdrawalAmount) {
            revert DocTokenHandler__WithdrawalAmountExceedsKdocBalance(user, withdrawalAmount, docInTropykus);
        }
        _redeemDoc(user, withdrawalAmount);
        super.withdrawToken(user, withdrawalAmount);
    }

    /**
     * @param buyer: the user on behalf of which the contract is making the rBTC purchase
     * @param purchaseAmount: the amount to spend on rBTC
     * @param purchasePeriod: the period between purchases
     * @notice this function will be called periodically through a CRON job running on a web server
     * @notice it is checked that the purchase period has elapsed, as added security on top of onlyOwner modifier
     */
    function buyRbtc(address buyer, bytes32 scheduleId, uint256 purchaseAmount, uint256 purchasePeriod)
        external
        override
        onlyDcaManager
    {
        // Redeem DOC (repaying kDOC)
        _redeemDoc(buyer, purchaseAmount);

        // Charge fee
        uint256 fee = _calculateFee(purchaseAmount, purchasePeriod);
        uint256 netPurchaseAmount = purchaseAmount - fee;
        _transferFee(fee);

        // Redeem rBTC repaying DOC
        (uint256 balancePrev, uint256 balancePost) = _redeemRbtc(netPurchaseAmount);

        // // (bool success,) = address(i_mocProxy).call(abi.encodeWithSignature("redeemDocRequest(uint256)", netPurchaseAmount));
        // // if (!success) revert DocTokenHandler__redeemDocRequestFailed();
        // try i_mocProxy.redeemDocRequest(netPurchaseAmount) {
        // } catch {
        //     revert DocTokenHandler__redeemDocRequestFailed();
        // }
        // // Now that redeemDocRequest has completed, proceed to redeemFreeDoc
        // uint256 balancePrev = address(this).balance;
        // // (success,) = address(i_mocProxy).call(abi.encodeWithSignature("redeemFreeDoc(uint256)", netPurchaseAmount));
        // // if (!success) revert DocTokenHandler__RedeemFreeDocFailed();
        // try i_mocProxy.redeemFreeDoc(netPurchaseAmount) {
        // } catch {
        //     revert DocTokenHandler__RedeemFreeDocFailed();
        // }
        // uint256 balancePost = address(this).balance;

        if (balancePost > balancePrev) {
            s_usersAccumulatedRbtc[buyer] += (balancePost - balancePrev);
            emit TokenHandler__RbtcBought(
                buyer, address(i_docToken), balancePost - balancePrev, scheduleId, netPurchaseAmount
            );
        } else {
            revert TokenHandler__RbtcPurchaseFailed(buyer, address(i_docToken));
        }
    }

    function batchBuyRbtc(
        address[] memory buyers,
        bytes32[] memory scheduleIds,
        uint256[] memory purchaseAmounts,
        uint256[] memory purchasePeriods
    ) external override onlyDcaManager {
        uint256 numOfPurchases = buyers.length;

        // Calculate net amounts
        (uint256 aggregatedFee, uint256[] memory netDocAmountsToSpend, uint256 totalDocAmountToSpend) =
            _calculateFeeAndNetAmounts(purchaseAmounts, purchasePeriods);

        // Redeem DOC (and repay kDOC)
        _batchRedeemDoc(buyers, purchaseAmounts, totalDocAmountToSpend + aggregatedFee); // total DOC to redeem by repaying kDOC in order to spend it to redeem rBTC is totalDocAmountToSpend + aggregatedFee

        // Charge fees
        _transferFee(aggregatedFee);

        // Redeem DOC for rBTC
        (uint256 balancePrev, uint256 balancePost) = _redeemRbtc(totalDocAmountToSpend);

        // try i_mocProxy.redeemDocRequest(totalDocAmountToSpend) {
        // } catch {
        //     revert DocTokenHandler__redeemDocRequestFailed();
        // }
        // uint256 balancePrev = address(this).balance;
        // try i_mocProxy.redeemFreeDoc(totalDocAmountToSpend) {
        // } catch {
        //     revert DocTokenHandler__RedeemFreeDocFailed();
        // }
        // uint256 balancePost = address(this).balance;

        if (balancePost > balancePrev) {
            uint256 totalPurchasedRbtc = balancePost - balancePrev;

            for (uint256 i; i < numOfPurchases; ++i) {
                uint256 usersPurchasedRbtc = totalPurchasedRbtc * netDocAmountsToSpend[i] / totalDocAmountToSpend;
                s_usersAccumulatedRbtc[buyers[i]] += usersPurchasedRbtc;
                emit TokenHandler__RbtcBought(
                    buyers[i], address(i_docToken), usersPurchasedRbtc, scheduleIds[i], netDocAmountsToSpend[i]
                );
            }
            emit TokenHandler__SuccessfulRbtcBatchPurchase(
                address(i_docToken), totalPurchasedRbtc, totalDocAmountToSpend
            );
        } else {
            revert TokenHandler__RbtcBatchPurchaseFailed(address(i_docToken));
        }
    }

    function getUsersKdocBalance(address user) external view override returns (uint256) {
        return s_kDocBalances[user];
    }

    function withdrawInterest(address user, uint256 docLockedInDcaSchedules) external override onlyDcaManager {
        uint256 exchangeRate = i_kDocToken.exchangeRateStored();
        uint256 totalDocInLending = _kdocToDoc(s_kDocBalances[user], exchangeRate);
        uint256 docInterestAmount = totalDocInLending - docLockedInDcaSchedules;
        uint256 kDocToRepay = docInterestAmount * EXCHANGE_RATE_DECIMALS / exchangeRate;
        // _redeemDoc(user, docInterestAmount);
        s_kDocBalances[user] -= kDocToRepay;
        uint256 result = i_kDocToken.redeemUnderlying(docInterestAmount);
        if (result == 0) emit DocTokenHandler__SuccessfulDocRedemption(user, docInterestAmount, kDocToRepay);
        else revert DocTokenHandler__RedeemUnderlyingFailed(result);
        i_docToken.safeTransfer(user, docInterestAmount);
        emit DocTokenHandler__SuccessfulInterestWithdrawal(user, docInterestAmount, kDocToRepay);

        // bool transferSuccess = i_docToken.safeTransfer(user, docInterestAmount);
        // if (!transferSuccess) revert DocTokenHandler__InterestWithdrawalFailed(user, docInterestAmount);
    }

    function getAccruedInterest(address user, uint256 docLockedInDcaSchedules)
        external
        view
        override
        onlyDcaManager
        returns (uint256 docInterestAmount)
    {
        uint256 totalDocInLending = _kdocToDoc(s_kDocBalances[user], i_kDocToken.exchangeRateStored());
        docInterestAmount = totalDocInLending - docLockedInDcaSchedules;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _calculateFeeAndNetAmounts(uint256[] memory purchaseAmounts, uint256[] memory purchasePeriods)
        internal
        view
        returns (uint256, uint256[] memory, uint256)
    {
        uint256 fee;
        uint256 aggregatedFee;
        uint256[] memory netDocAmountsToSpend = new uint256[](purchaseAmounts.length);
        uint256 totalDocAmountToSpend;
        for (uint256 i; i < purchaseAmounts.length; ++i) {
            fee = _calculateFee(purchaseAmounts[i], purchasePeriods[i]);
            aggregatedFee += fee;
            netDocAmountsToSpend[i] = purchaseAmounts[i] - fee;
            totalDocAmountToSpend += netDocAmountsToSpend[i];
        }
        return (aggregatedFee, netDocAmountsToSpend, totalDocAmountToSpend);
    }

    /**
     * @notice the guys at Money on Chain mistakenly named their functions as "redeem DOC", when it is rBTC that gets redeemed (by repaying DOC)
     * @param docAmountToSpend the amount of DOC to repay to redeem rBTC
     */
    function _redeemRbtc(uint256 docAmountToSpend) internal returns (uint256, uint256) {
        try i_mocProxy.redeemDocRequest(docAmountToSpend) {}
        catch {
            revert DocTokenHandler__RedeemDocRequestFailed();
        }
        uint256 balancePrev = address(this).balance;
        try i_mocProxy.redeemFreeDoc(docAmountToSpend) {}
        catch {
            revert DocTokenHandler__RedeemFreeDocFailed();
        }
        uint256 balancePost = address(this).balance;
        return (balancePrev, balancePost);
    }

    function _redeemDoc(address user, uint256 docToRedeem) internal {
        // (, uint256 underlyingAmount,,) = i_kDocToken.getSupplierSnapshotStored(address(this)); // esto devuelve el DOC retirable por la dirección de nuestro contrato en la última actualización de mercado
        // if (docToRedeem > underlyingAmount) {
        //     revert DocTokenHandler__DocRedeemAmountExceedsBalance(docToRedeem, underlyingAmount);
        // } // NO SÉ SI ESTO TIENE MUCHO SENTIDO
        uint256 exchangeRate = i_kDocToken.exchangeRateStored(); // esto devuelve la tasa de cambio
        uint256 usersKdocBalance = s_kDocBalances[user];
        uint256 kDocToRepay = _docToKdoc(docToRedeem, exchangeRate);
        if (kDocToRepay > usersKdocBalance) {
            revert DocTokenHandler__KdocToRepayExceedsUsersBalance(user, docToRedeem * exchangeRate, usersKdocBalance);
        }
        s_kDocBalances[user] -= kDocToRepay;
        uint256 result = i_kDocToken.redeemUnderlying(docToRedeem);
        if (result == 0) emit DocTokenHandler__SuccessfulDocRedemption(user, docToRedeem, kDocToRepay);
        else revert DocTokenHandler__RedeemUnderlyingFailed(result);
    }

    function _batchRedeemDoc(address[] memory users, uint256[] memory purchaseAmounts, uint256 totalDocToRedeem)
        internal
    {
        (, uint256 underlyingAmount,,) = i_kDocToken.getSupplierSnapshotStored(address(this)); // esto devuelve el DOC retirable por la dirección de nuestro contrato en la última actualización de mercado
        if (totalDocToRedeem > underlyingAmount) {
            revert DocTokenHandler__DocRedeemAmountExceedsBalance(totalDocToRedeem, underlyingAmount);
        }
        uint256 totalKdocToRepay = _docToKdoc(totalDocToRedeem, i_kDocToken.exchangeRateStored());

        // TODO: delete this commented code after further testing (we realised this could be done following CEI)
        // @notice here we don't follow CEI, but this function is protected by an onlyDcaManager modifier
        // uint256 kDocBalancePrev = i_kDocToken.balanceOf(address(this));
        // i_kDocToken.redeemUnderlying(totalDocToRedeem);
        // uint256 kDocBalancePost = i_kDocToken.balanceOf(address(this));

        // if (kDocToRepay != kDocBalancePrev - kDocBalancePost) revert("PERO QUE COJONES");

        // if (kDocBalancePrev - kDocBalancePost > 0) {
        //     uint256 totalKdocRepayed = kDocBalancePrev - kDocBalancePost;
        //     uint256 numOfPurchases = users.length;
        //     for (uint256 i; i < numOfPurchases; ++i) {
        //         // @notice the amount of kDOC each user repays is proportional to the ratio of that user's DOC getting redeemed over the total DOC getting redeemed
        //         uint256 usersRepayedKdoc = totalKdocRepayed * purchaseAmounts[i] / totalDocToRedeem;
        //         s_kDocBalances[users[i]] -= usersRepayedKdoc;
        //         emit DocTokenHandler__DocRedeemedKdocRepayed(users[i], purchaseAmounts[i], usersRepayedKdoc);
        //     }
        //     emit DocTokenHandler__SuccessfulBatchDocRedemption(totalDocToRedeem, totalKdocRepayed);
        // } else {
        //     revert DocTokenHandler__BatchRedeemDocFailed();
        // }

        uint256 numOfPurchases = users.length;
        for (uint256 i; i < numOfPurchases; ++i) {
            // @notice the amount of kDOC each user repays is proportional to the ratio of that user's DOC getting redeemed over the total DOC getting redeemed
            uint256 usersRepayedKdoc = totalKdocToRepay * purchaseAmounts[i] / totalDocToRedeem;
            s_kDocBalances[users[i]] -= usersRepayedKdoc;
            emit DocTokenHandler__DocRedeemedKdocRepayed(users[i], purchaseAmounts[i], usersRepayedKdoc);
        }
        uint256 result = i_kDocToken.redeemUnderlying(totalDocToRedeem);
        if (result == 0) emit DocTokenHandler__SuccessfulBatchDocRedemption(totalDocToRedeem, totalKdocToRepay);
        else revert DocTokenHandler__BatchRedeemDocFailed();
    }

    function _docToKdoc(uint256 docAmount, uint256 exchangeRate) internal pure returns (uint256 kDocAmount) {
        kDocAmount = docAmount * EXCHANGE_RATE_DECIMALS / exchangeRate;
    }

    function _kdocToDoc(uint256 kDocAmount, uint256 exchangeRate) internal pure returns (uint256 docAmount) {
        docAmount = kDocAmount * exchangeRate / EXCHANGE_RATE_DECIMALS;
    }
}
