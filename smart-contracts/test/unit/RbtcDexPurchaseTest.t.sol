//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {DcaDappTest} from "./DcaDappTest.t.sol";
// // import {RbtcBaseTest} from "./RbtcBaseTest.t.sol";
// import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
// import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
// import "../Constants.sol";

// contract RbtcDexPurchaseTest is DcaDappTest {
//     function setUp() public override {
//         super.setUp();
//     }

//     //////////////////////
//     /// Purchase tests ///
//     //////////////////////
//     function testSinglePurchase() external {
//         super.makeSinglePurchase();
//     }

//     function testCannotBuyIfPeriodNotElapsed() external {
//         vm.startPrank(USER);
//         mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
//         dcaManager.setPurchaseAmount(address(mockDocToken), SCHEDULE_INDEX, DOC_TO_SPEND);
//         dcaManager.setPurchasePeriod(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_PERIOD);
//         // bytes32 scheduleId = dcaManager.getScheduleId(address(mockDocToken), SCHEDULE_INDEX);
//         bytes32 scheduleId = keccak256(abi.encodePacked(USER, block.timestamp));
//         vm.stopPrank();
//         vm.prank(OWNER);
//         dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX, scheduleId); // first purchase
//         bytes memory encodedRevert = abi.encodeWithSelector(
//             IDcaManager.DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed.selector,
//             block.timestamp + MIN_PURCHASE_PERIOD - block.timestamp
//         );
//         vm.expectRevert(encodedRevert);
//         vm.prank(OWNER);
//         dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX, scheduleId); // second purchase
//     }

//     function testSeveralPurchasesOneSchedule() external {
//         uint256 numOfPurchases = 5;

//         uint256 fee = feeCalculator.calculateFee(DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
//         uint256 netPurchaseAmount = DOC_TO_SPEND - fee;

//         bytes32 scheduleId = keccak256(abi.encodePacked(USER, block.timestamp));

//         vm.prank(USER);
//         dcaManager.setPurchasePeriod(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_PERIOD);
//         for (uint256 i; i < numOfPurchases; ++i) {
//             vm.prank(OWNER);
//             dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX, scheduleId);
//             vm.warp(vm.getBlockTimestamp() + MIN_PURCHASE_PERIOD);
//         }
//         vm.prank(USER);
//         assertEq(docTokenHandler.getAccumulatedRbtcBalance(), (netPurchaseAmount / BTC_PRICE) * numOfPurchases);
//     }

//     function testRevertPurchasetIfDocRunsOut() external {
//         uint256 numOfPurchases = DOC_TO_DEPOSIT / DOC_TO_SPEND;
//         bytes32 scheduleId = keccak256(abi.encodePacked(USER, block.timestamp));
//         for (uint256 i; i < numOfPurchases; ++i) {
//             vm.prank(OWNER);
//             dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX, scheduleId);
//             vm.warp(vm.getBlockTimestamp() + MIN_PURCHASE_PERIOD);
//         }
//         // Attempt to purchase once more
//         bytes memory encodedRevert = abi.encodeWithSelector(
//             IDcaManager.DcaManager__ScheduleBalanceNotEnoughForPurchase.selector, address(mockDocToken), 0
//         );
//         vm.expectRevert(encodedRevert);
//         vm.prank(OWNER);
//         dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX, scheduleId);
//     }

//     function testSeveralPurchasesWithSeveralSchedules() external {
//         super.createSeveralDcaSchedules();
//         super.makeSeveralPurchasesWithSeveralSchedules();
//     }

//     function testOnlyOwnerCanCallDcaManagerToPurchase() external {
//         vm.startPrank(USER);
//         uint256 docBalanceBeforePurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
//         uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
//         bytes memory encodedRevert = abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER);
//         bytes32 scheduleId = keccak256(abi.encodePacked(USER, block.timestamp));
//         vm.expectRevert(encodedRevert);
//         dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX, scheduleId);
//         uint256 docBalanceAfterPurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
//         uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
//         vm.stopPrank();
//         // Check that balances didn't change
//         assertEq(docBalanceBeforePurchase, docBalanceAfterPurchase);
//         assertEq(RbtcBalanceAfterPurchase, RbtcBalanceBeforePurchase);
//     }

//     function testOnlyDcaManagerCanPurchase() external {
//         vm.startPrank(USER);
//         uint256 docBalanceBeforePurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
//         uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
//         vm.expectRevert(ITokenHandler.TokenHandler__OnlyDcaManagerCanCall.selector);
//         bytes32 scheduleId = keccak256(abi.encodePacked(USER, block.timestamp));
//         docTokenHandler.buyRbtc(USER, scheduleId, MIN_PURCHASE_AMOUNT, MIN_PURCHASE_PERIOD);
//         uint256 docBalanceAfterPurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
//         uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
//         vm.stopPrank();
//         // Check that balances didn't change
//         assertEq(docBalanceBeforePurchase, docBalanceAfterPurchase);
//         assertEq(RbtcBalanceAfterPurchase, RbtcBalanceBeforePurchase);
//     }

//     function testBatchPurchasesOneUser() external {
//         super.createSeveralDcaSchedules();
//         super.makeBatchPurchasesOneUser();
//     }

//     function testBatchPurchaseFailsIfArraysEmpty() external {
//         address[] memory emptyAddressArray;
//         uint256[] memory emptyUintArray;
//         bytes32[] memory emptyBytes32Array;
//         vm.expectRevert(IDcaManager.DcaManager__EmptyBatchPurchaseArrays.selector);
//         vm.prank(OWNER);
//         dcaManager.batchBuyRbtc(
//             emptyAddressArray, address(mockDocToken), emptyUintArray, emptyBytes32Array, emptyUintArray, emptyUintArray
//         );
//     }

//     function testBatchPurchaseFailsIfArraysHaveDifferentLenghts() external {
//         address[] memory users = new address[](1);
//         uint256[] memory dummyUintArray = new uint256[](3);
//         bytes32[] memory dummyBytes32Array = new bytes32[](3);
//         vm.expectRevert(IDcaManager.DcaManager__BatchPurchaseArraysLengthMismatch.selector);
//         vm.prank(OWNER);
//         dcaManager.batchBuyRbtc(
//             users, address(mockDocToken), dummyUintArray, dummyBytes32Array, dummyUintArray, dummyUintArray
//         );
//     }

//     function testPurchaseFailsIfIdAndIndexDontMatch() external {
//         bytes32 scheduleId = keccak256(abi.encodePacked("dummyStuff", block.timestamp));

//         vm.startPrank(USER);
//         uint256 docBalanceBeforePurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
//         uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
//         vm.stopPrank();

//         vm.expectRevert(IDcaManager.DcaManager__ScheduleIdAndIndexMismatch.selector);
//         vm.prank(OWNER);
//         dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX, scheduleId);

//         vm.startPrank(USER);
//         uint256 docBalanceAfterPurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
//         uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
//         vm.stopPrank();

//         // Check that there are no changes in balances
//         assertEq(docBalanceBeforePurchase - docBalanceAfterPurchase, 0);
//         assertEq(RbtcBalanceAfterPurchase - RbtcBalanceBeforePurchase, 0);
//     }

//     function testBatchPurchaseFailsIfIdAndIndexDontMatch() external {
//         super.createSeveralDcaSchedules();

//         bytes32 scheduleId = keccak256(abi.encodePacked("dummyStuff", block.timestamp));

//         uint256 prevDocTokenHandlerBalance = address(docTokenHandler).balance;
//         vm.prank(USER);
//         uint256 userAccumulatedRbtcPrev = docTokenHandler.getAccumulatedRbtcBalance();
//         // vm.prank(OWNER);
//         // address user = dcaManager.getUsers()[0]; // Only one user in this test, but several schedules
//         // uint256 numOfPurchases = dcaManager.ownerGetUsersDcaSchedules(user, address(mockDocToken)).length;
//         address[] memory users = new address[](NUM_OF_SCHEDULES);
//         uint256[] memory scheduleIndexes = new uint256[](NUM_OF_SCHEDULES);
//         uint256[] memory purchaseAmounts = new uint256[](NUM_OF_SCHEDULES);
//         uint256[] memory purchasePeriods = new uint256[](NUM_OF_SCHEDULES);
//         bytes32[] memory scheduleIds = new bytes32[](NUM_OF_SCHEDULES);

//         uint256 totalNetPurchaseAmount;

//         // Create the arrays for the batch purchase (in production, this is done in the back end)
//         for (uint8 i; i < NUM_OF_SCHEDULES; ++i) {
//             uint256 scheduleIndex = i;
//             vm.startPrank(USER);
//             uint256 schedulePurchaseAmount = dcaManager.getSchedulePurchaseAmount(address(mockDocToken), scheduleIndex);
//             uint256 schedulePurchasePeriod = dcaManager.getSchedulePurchasePeriod(address(mockDocToken), scheduleIndex);
//             vm.stopPrank();
//             uint256 fee = feeCalculator.calculateFee(schedulePurchaseAmount, schedulePurchasePeriod);
//             totalNetPurchaseAmount += schedulePurchaseAmount - fee;

//             users[i] = USER; // Same user for has 5 schedules due for a purchase in this scenario
//             scheduleIndexes[i] = i;
//             vm.startPrank(OWNER);
//             purchaseAmounts[i] = dcaManager.ownerGetUsersDcaSchedules(users[0], address(mockDocToken))[i].purchaseAmount;
//             purchasePeriods[i] = dcaManager.ownerGetUsersDcaSchedules(users[0], address(mockDocToken))[i].purchasePeriod;
//             scheduleIds[i] = scheduleId;
//             vm.stopPrank();
//         }
//         vm.expectRevert(IDcaManager.DcaManager__ScheduleIdAndIndexMismatch.selector);
//         vm.prank(OWNER);
//         dcaManager.batchBuyRbtc(
//             users, address(mockDocToken), scheduleIndexes, scheduleIds, purchaseAmounts, purchasePeriods
//         );

//         uint256 postDocTokenHandlerBalance = address(docTokenHandler).balance;

//         // The balance of the DOC token handler contract gets incremented in exactly the purchased amount of rBTC
//         assertEq(postDocTokenHandlerBalance - prevDocTokenHandlerBalance, 0);

//         vm.prank(USER);
//         uint256 userAccumulatedRbtcPost = docTokenHandler.getAccumulatedRbtcBalance();
//         // The user's balance is also equal (since we're batching the purchases of 5 schedules but only one user)
//         assertEq(userAccumulatedRbtcPost - userAccumulatedRbtcPrev, 0);
//     }
// }
