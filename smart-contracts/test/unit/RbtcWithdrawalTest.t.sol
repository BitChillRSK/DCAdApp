//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
import "../Constants.sol";

contract RbtcWithdrawalTest is DcaDappTest {
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////
    /// rBTC Withdrawal tests ///
    /////////////////////////////

    function testWithdrawRbtcAfterOnePurchase() external {
        // TODO: test this for multiple stablecoins/schedules

        uint256 fee = feeCalculator.calculateFee(DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        uint256 netPurchaseAmount = DOC_TO_SPEND - fee;

        vm.prank(USER);
        IDcaManager.DcaDetails[] memory dcaDetails = dcaManager.getMyDcaSchedules(address(mockDocToken));

        // vm.prank(OWNER);
        vm.prank(SWAPPER);
        dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX, dcaDetails[SCHEDULE_INDEX].scheduleId);

        uint256 rbtcBalanceBeforeWithdrawal = USER.balance;
        vm.prank(USER);
        dcaManager.withdrawAllAccmulatedRbtc();
        uint256 rbtcBalanceAfterWithdrawal = USER.balance;
        assertEq(rbtcBalanceAfterWithdrawal - rbtcBalanceBeforeWithdrawal, netPurchaseAmount / BTC_PRICE);
    }

    function testWithdrawRbtcAfterSeveralPurchases() external {
        super.createSeveralDcaSchedules();
        uint256 totalDocSpent = super.makeSeveralPurchasesWithSeveralSchedules(); // 5 purchases
        uint256 rbtcBalanceBeforeWithdrawal = USER.balance;
        vm.prank(USER);
        dcaManager.withdrawAllAccmulatedRbtc();
        uint256 rbtcBalanceAfterWithdrawal = USER.balance;
        assertEq(rbtcBalanceAfterWithdrawal - rbtcBalanceBeforeWithdrawal, totalDocSpent / BTC_PRICE);
    }

    function testCannotWithdrawBeforePurchasing() external {
        uint256 rbtcBalanceBeforeWithdrawal = USER.balance;
        vm.expectRevert(ITokenHandler.TokenHandler__NoAccumulatedRbtcToWithdraw.selector);
        vm.prank(USER);
        dcaManager.withdrawAllAccmulatedRbtc();
        uint256 rbtcBalanceAfterWithdrawal = USER.balance;
        assertEq(rbtcBalanceAfterWithdrawal, rbtcBalanceBeforeWithdrawal);
    }
}
