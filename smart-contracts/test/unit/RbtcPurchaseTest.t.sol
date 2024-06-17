//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
// import {RbtcBaseTest} from "./RbtcBaseTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
import "../Constants.sol";

contract RbtcPurchaseTest is DcaDappTest {

    function setUp() public override {
        super.setUp();
    }
    
    //////////////////////
    /// Purchase tests ///
    //////////////////////
    function testSinglePurchase() external {
        super.makeSinglePurchase();
    }

    function testCannotBuyIfPeriodNotElapsed() external {
        vm.startPrank(USER);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
        dcaManager.setPurchaseAmount(address(mockDocToken), SCHEDULE_INDEX, DOC_TO_SPEND);
        dcaManager.setPurchasePeriod(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_PERIOD);
        vm.stopPrank();
        vm.prank(OWNER);
        dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX); // first purchase
        bytes memory encodedRevert = abi.encodeWithSelector(
            IDcaManager.DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed.selector,
            block.timestamp + MIN_PURCHASE_PERIOD - block.timestamp
        );
        vm.expectRevert(encodedRevert);
        vm.prank(OWNER);
        dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX); // second purchase
    }

    function testSeveralPurchasesOneSchedule() external {
        uint256 numOfPurchases = 5;

        uint256 fee = feeCalculator.calculateFee(DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        uint256 netPurchaseAmount = DOC_TO_SPEND - fee;

        vm.prank(USER);
        dcaManager.setPurchasePeriod(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_PERIOD);
        for (uint256 i; i < numOfPurchases; ++i) {
            vm.prank(OWNER);
            dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);
            vm.warp(block.timestamp + MIN_PURCHASE_PERIOD);
        }
        vm.prank(USER);
        assertEq(docTokenHandler.getAccumulatedRbtcBalance(), (netPurchaseAmount / BTC_PRICE) * numOfPurchases);
    }

    function testRevertPurchasetIfDocRunsOut() external {
        uint256 numOfPurchases = DOC_TO_DEPOSIT / DOC_TO_SPEND;
        for (uint256 i; i < numOfPurchases; ++i) {
            vm.prank(OWNER);
            dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);
            vm.warp(block.timestamp + MIN_PURCHASE_PERIOD);
        }
        // Attempt to purchase once more
        bytes memory encodedRevert = abi.encodeWithSelector(
            IDcaManager.DcaManager__ScheduleBalanceNotEnoughForPurchase.selector, address(mockDocToken), 0
        );
        vm.expectRevert(encodedRevert);
        vm.prank(OWNER);
        dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);
    }

    function testSeveralPurchasesWithSeveralSchedules() external {
        super.createSeveralDcaSchedules();
        super.makeSeveralPurchasesWithSeveralSchedules();
    }

    function testOnlyOwnerCanCallDcaManagerToPurchase() external {
        vm.startPrank(USER);
        uint256 docBalanceBeforePurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
        bytes memory encodedRevert = abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER);
        vm.expectRevert(encodedRevert);
        dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);
        uint256 docBalanceAfterPurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
        vm.stopPrank();
        // Check that balances didn't change
        assertEq(docBalanceBeforePurchase, docBalanceAfterPurchase);
        assertEq(RbtcBalanceAfterPurchase, RbtcBalanceBeforePurchase);
    }

    function testOnlyDcaManagerCanPurchase() external {
        vm.startPrank(USER);
        uint256 docBalanceBeforePurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
        vm.expectRevert(ITokenHandler.TokenHandler__OnlyDcaManagerCanCall.selector);
        docTokenHandler.buyRbtc(USER, MIN_PURCHASE_AMOUNT, MIN_PURCHASE_PERIOD);
        uint256 docBalanceAfterPurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
        vm.stopPrank();
        // Check that balances didn't change
        assertEq(docBalanceBeforePurchase, docBalanceAfterPurchase);
        assertEq(RbtcBalanceAfterPurchase, RbtcBalanceBeforePurchase);
    }

    function testBatchPurchasesOneUser() external {
        super.createSeveralDcaSchedules();
        super.makeBatchPurchasesOneUser();
    }

    function testBatchPurchaseFailsIfArraysEmpty() external {
        address[] memory emptyAddressArray;
        uint256[] memory emptyUintArray;
        vm.expectRevert(IDcaManager.DcaManager__EmptyBatchPurchaseArrays.selector);
        vm.prank(OWNER);
        dcaManager.batchBuyRbtc(emptyAddressArray, address(mockDocToken), emptyUintArray, emptyUintArray, emptyUintArray);
    }

    function testBatchPurchaseFailsIfArraysHaveDifferentLenghts() external {
        address[] memory users = new address[](1);
        uint256[] memory dummyUintArray = new uint256[](3);
        vm.expectRevert(IDcaManager.DcaManager__BatchPurchaseArraysLengthMismatch.selector);
        vm.prank(OWNER);
        dcaManager.batchBuyRbtc(users, address(mockDocToken), dummyUintArray, dummyUintArray, dummyUintArray);
    }
}