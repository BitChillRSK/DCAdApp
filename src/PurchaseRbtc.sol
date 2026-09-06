// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {IPurchaseRbtc} from "src/interfaces/IPurchaseRbtc.sol";
import {DcaManagerAccessControl} from "./DcaManagerAccessControl.sol";
import {FeeHandler} from "./FeeHandler.sol";
import {StablecoinSource} from "./StablecoinSource.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PurchaseRbtc
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @notice Shared rBTC purchase pipeline, accumulated-balance accounting, and signer withdrawals.
 */
abstract contract PurchaseRbtc is IPurchaseRbtc, FeeHandler, DcaManagerAccessControl, StablecoinSource {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address user => uint256 amount) internal s_usersAccumulatedRbtc;

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allow the contract to receive native rBTC from MoC or from unwrapping WRBTC.
     */
    receive() external payable {}

    /**
     * @inheritdoc IPurchaseRbtc
     * @dev Spends the stablecoin the retrieval actually delivered, never the gross amount it was asked
     *      for: a lending handler can come back short when it redeems its shares, while the idle handler
     *      reverts rather than under-deliver. Planned net amounts are only allocation weights for every
     *      row before the last; the last row is credited the measured total minus the floors already
     *      handed out, so the sum of this batch's credits equals the rBTC the venue leg measured rather
     *      than falling up to one wei short per row. There is no owner sweep of that residue, which is
     *      why it is credited here instead of accepted.
     */
    function batchBuyRbtc(
        address[] memory buyers,
        uint64[] memory scheduleIds,
        uint256[] memory purchaseAmounts,
        uint256 minRbtcOut
    ) external override onlyDcaManager {
        uint256[] memory netStablecoinAmountsToSpend;
        uint256 totalNetStablecoinPlanned;
        uint256 totalStablecoinAmountToSpend;
        IERC20 purchaseToken;

        // `aggregatedFee` is scoped to this block because it is dead once the fee is paid.
        {
            uint256 aggregatedFee;
            // Calculate net amounts
            (aggregatedFee, netStablecoinAmountsToSpend, totalNetStablecoinPlanned) =
                _calculateFeeAndNetAmounts(purchaseAmounts);

            // Retrieve the stablecoin to spend: the net amount destined for rBTC plus the fee BitChill
            // charges. What comes back is what the retrieval delivered, which a lending handler can leave
            // short of the request.
            totalStablecoinAmountToSpend =
                _batchRetrieveStablecoin(buyers, purchaseAmounts);
            if (totalStablecoinAmountToSpend <= aggregatedFee) {
                revert PurchaseRbtc__StablecoinRetrievedBelowFee(totalStablecoinAmountToSpend, aggregatedFee);
            }
            totalStablecoinAmountToSpend -= aggregatedFee;

            purchaseToken = _purchaseToken();
            _transferFee(purchaseToken, aggregatedFee);
        }

        uint256 totalPurchasedRbtc = _purchaseRbtc(totalStablecoinAmountToSpend, minRbtcOut);
        if (totalPurchasedRbtc == 0) revert PurchaseRbtc__RbtcBatchPurchaseFailed(address(purchaseToken));
        // Checked against the rBTC we measured ourselves receiving, so the bound holds on every purchase
        // venue and never trusts an integrator return value. Equality passes. Where the venue applies a
        // floor of its own, it is enforced there and the stricter of the two decides.
        if (totalPurchasedRbtc < minRbtcOut) {
            revert PurchaseRbtc__BelowSwapperMinimum(totalPurchasedRbtc, minRbtcOut);
        }

        // Every row but the last takes a floor share of what actually moved, weighted by its planned
        // net; the last row takes the measured total minus those floors. Only the rBTC side carries a
        // running sum, because only the rBTC side is custody: the stablecoin has already left for the
        // venue, so its per-row figure is a report and stays a floor. The tail is written out here
        // rather than branched on inside the loop so the row body the swapper pays for stays straight
        // line. Which row is last is the caller's batch order, not a claim about who deserves the
        // remainder; at under one wei per row there is nothing to allocate fairly.
        uint256 lastRow = buyers.length - 1;
        uint256 rbtcCredited;
        for (uint256 i; i < lastRow; ++i) {
            uint256 plannedNet = netStablecoinAmountsToSpend[i];
            address buyer = buyers[i];
            uint256 usersPurchasedRbtc = totalPurchasedRbtc * plannedNet / totalNetStablecoinPlanned;
            uint256 usersStablecoinSpent = totalStablecoinAmountToSpend * plannedNet / totalNetStablecoinPlanned;
            rbtcCredited += usersPurchasedRbtc;
            s_usersAccumulatedRbtc[buyer] += usersPurchasedRbtc;
            emit PurchaseRbtc__RbtcBought(
                buyer, address(purchaseToken), usersPurchasedRbtc, scheduleIds[i], usersStablecoinSpent
            );
        }
        {
            uint256 plannedNet = netStablecoinAmountsToSpend[lastRow];
            address lastBuyer = buyers[lastRow];
            uint256 usersPurchasedRbtc = totalPurchasedRbtc - rbtcCredited;
            uint256 usersStablecoinSpent = totalStablecoinAmountToSpend * plannedNet / totalNetStablecoinPlanned;
            s_usersAccumulatedRbtc[lastBuyer] += usersPurchasedRbtc;
            emit PurchaseRbtc__RbtcBought(
                lastBuyer, address(purchaseToken), usersPurchasedRbtc, scheduleIds[lastRow], usersStablecoinSpent
            );
        }
        emit PurchaseRbtc__SuccessfulRbtcBatchPurchase(
            address(purchaseToken), totalPurchasedRbtc, totalStablecoinAmountToSpend
        );
    }

    /**
     * @inheritdoc IPurchaseRbtc
     */
    function withdrawAccumulatedRbtc(address user) external virtual override onlyDcaManager {
        uint256 rbtcBalance = _withdrawRbtcChecksEffects(user);
        _withdrawRbtc(user, rbtcBalance);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPurchaseRbtc
     */
    function getAccumulatedRbtcBalance(address user) external view override returns (uint256) {
        return s_usersAccumulatedRbtc[user];
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Zero the user's accumulated balance after checking it is nonzero. Caller then pays.
     */
    function _withdrawRbtcChecksEffects(address user) internal returns (uint256) {
        uint256 rbtcBalance = s_usersAccumulatedRbtc[user];
        if (rbtcBalance == 0) revert PurchaseRbtc__NoAccumulatedRbtcToWithdraw();

        s_usersAccumulatedRbtc[user] = 0;
        return rbtcBalance;
    }

    /**
     * @dev Pay `rbtcBalance` native rBTC to `user`. Reverts if the call fails.
     */
    function _withdrawRbtc(address user, uint256 rbtcBalance) internal {
        (bool sent,) = user.call{value: rbtcBalance}("");
        if (!sent) revert PurchaseRbtc__rBtcWithdrawalFailed();
        emit PurchaseRbtc__rBtcWithdrawn(user, rbtcBalance);
    }

    /**
     * @dev Spend `stablecoinAmount` of net stablecoin and return only measured rBTC or WRBTC received.
     */
    function _purchaseRbtc(uint256 stablecoinAmount, uint256 minRbtcOut) internal virtual returns (uint256 rbtcReceived);
}
