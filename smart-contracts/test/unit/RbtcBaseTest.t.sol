//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// import {Test, console} from "forge-std/Test.sol";
// import {DcaDappTest} from "./DcaDappTest.t.sol";
// import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
// import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
// import "../../src/test/Constants.sol";

// contract RbtcBaseTest is DcaDappTest {

//     function setUp() public override virtual {
//         super.setUp();
//     }
    
//     function createSeveralDcaSchedules() external { 
//         vm.startPrank(USER);
//         mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
//         uint256 docToDeposit = DOC_TO_DEPOSIT / NUM_OF_SCHEDULES;
//         uint256 purchaseAmount = DOC_TO_SPEND / NUM_OF_SCHEDULES;
//         for (uint256 i = 1; i < NUM_OF_SCHEDULES; ++i) { // Start from 1 since schedule 0 is created in setUp
//             uint256 scheduleIndex = SCHEDULE_INDEX + i;
//             uint256 purchasePeriod = MIN_PURCHASE_PERIOD + i * 5 days;
//             uint256 userBalanceBeforeDeposit;
//             if (dcaManager.getMyDcaSchedules(address(mockDocToken)).length > scheduleIndex) {
//                 userBalanceBeforeDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
//             } else {
//                 userBalanceBeforeDeposit = 0;
//             }
//             vm.expectEmit(true, true, true, true);
//             emit DcaManager__DcaScheduleCreated(
//                 USER, address(mockDocToken), scheduleIndex, docToDeposit, purchaseAmount, purchasePeriod
//             );
//             dcaManager.createDcaSchedule(
//                 address(mockDocToken), docToDeposit, purchaseAmount, purchasePeriod
//             );
//             uint256 userBalanceAfterDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex); 
//     }
    
//     function severalPurchasesWithSeveralSchedules() external {  
//     }

    // function testCannotBuyIfPeriodNotElapsed() external {
    //     vm.startPrank(USER);
    //     mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
    //     dcaManager.setPurchaseAmount(address(mockDocToken), SCHEDULE_INDEX, DOC_TO_SPEND);
    //     dcaManager.setPurchasePeriod(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_PERIOD);
    //     vm.stopPrank();
    //     vm.prank(OWNER);
    //     dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX); // first purchase
    //     bytes memory encodedRevert = abi.encodeWithSelector(
    //         IDcaManager.DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed.selector,
    //         block.timestamp + MIN_PURCHASE_PERIOD - block.timestamp
    //     );
    //     vm.expectRevert(encodedRevert);
    //     vm.prank(OWNER);
    //     dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX); // second purchase
    // }

    // function testSeveralPurchasesOneSchedule() external {
    //     uint256 numOfPurchases = 5;

    //     uint256 fee = feeCalculator.calculateFee(DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
    //     uint256 netPurchaseAmount = DOC_TO_SPEND - fee;

    //     vm.prank(USER);
    //     dcaManager.setPurchasePeriod(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_PERIOD);
    //     for (uint256 i; i < numOfPurchases; ++i) {
    //         vm.prank(OWNER);
    //         dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);
    //         vm.warp(block.timestamp + MIN_PURCHASE_PERIOD);
    //     }
    //     vm.prank(USER);
    //     assertEq(docTokenHandler.getAccumulatedRbtcBalance(), (netPurchaseAmount / BTC_PRICE) * numOfPurchases);
    // }

    // function testRevertPurchasetIfDocRunsOut() external {
    //     uint256 numOfPurchases = DOC_TO_DEPOSIT / DOC_TO_SPEND;
    //     for (uint256 i; i < numOfPurchases; ++i) {
    //         vm.prank(OWNER);
    //         dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);
    //         vm.warp(block.timestamp + MIN_PURCHASE_PERIOD);
    //     }
    //     // Attempt to purchase once more
    //     bytes memory encodedRevert = abi.encodeWithSelector(
    //         IDcaManager.DcaManager__ScheduleBalanceNotEnoughForPurchase.selector, address(mockDocToken), 0
    //     );
    //     vm.expectRevert(encodedRevert);
    //     vm.prank(OWNER);
    //     dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);
    // }

    // function testSeveralPurchasesWithSeveralSchedules() external returns(uint256 totalDocSpent) {
    //     this.testCreateSeveralDcaSchedules();

    //     uint8 numOfPurchases = 5;

    //     for (uint8 i; i < NUM_OF_SCHEDULES; ++i) { 
    //         uint256 scheduleIndex = i;
    //         vm.startPrank(USER);
    //         uint256 schedulePurchaseAmount = dcaManager.getSchedulePurchaseAmount(address(mockDocToken), scheduleIndex);
    //         uint256 schedulePurchasePeriod = dcaManager.getSchedulePurchasePeriod(address(mockDocToken), scheduleIndex);
    //         vm.stopPrank();
    //         uint256 fee = feeCalculator.calculateFee(schedulePurchaseAmount, schedulePurchasePeriod);
    //         uint256 netPurchaseAmount = schedulePurchaseAmount - fee;

    //         for (uint8 j; j < numOfPurchases; ++j) {
    //             vm.startPrank(USER);
    //             uint256 docBalanceBeforePurchase =
    //                 dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
    //             uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
    //             vm.stopPrank();
    //             vm.prank(OWNER);
    //             dcaManager.buyRbtc(USER, address(mockDocToken), scheduleIndex);
    //             vm.startPrank(USER);
    //             uint256 docBalanceAfterPurchase =
    //                 dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
    //             uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
    //             vm.stopPrank();
    //             // Check that DOC was substracted and rBTC was added to user's balances
    //             assertEq(docBalanceBeforePurchase - docBalanceAfterPurchase, schedulePurchaseAmount);
    //             assertEq(RbtcBalanceAfterPurchase - RbtcBalanceBeforePurchase, netPurchaseAmount / BTC_PRICE);

    //             totalDocSpent += netPurchaseAmount;

    //             vm.warp(block.timestamp + schedulePurchasePeriod);
    //         }
    //     }
    //     vm.prank(USER);
    //     // assertEq(docTokenHandler.getAccumulatedRbtcBalance(), (netPurchaseAmount / BTC_PRICE) * numOfPurchases);
    //     assertEq(docTokenHandler.getAccumulatedRbtcBalance(), totalDocSpent / BTC_PRICE);
    // }

    // function testOnlyOwnerCanCallDcaManagerToPurchase() external {
    //     vm.startPrank(USER);
    //     uint256 docBalanceBeforePurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
    //     uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
    //     bytes memory encodedRevert = abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER);
    //     vm.expectRevert(encodedRevert);
    //     dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);
    //     uint256 docBalanceAfterPurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
    //     uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
    //     vm.stopPrank();
    //     // Check that balances didn't change
    //     assertEq(docBalanceBeforePurchase, docBalanceAfterPurchase);
    //     assertEq(RbtcBalanceAfterPurchase, RbtcBalanceBeforePurchase);
    // }

    // function testOnlyDcaManagerCanPurchase() external {
    //     vm.startPrank(USER);
    //     uint256 docBalanceBeforePurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
    //     uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
    //     vm.expectRevert(ITokenHandler.TokenHandler__OnlyDcaManagerCanCall.selector);
    //     docTokenHandler.buyRbtc(USER, MIN_PURCHASE_AMOUNT, MIN_PURCHASE_PERIOD);
    //     uint256 docBalanceAfterPurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
    //     uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
    //     vm.stopPrank();
    //     // Check that balances didn't change
    //     assertEq(docBalanceBeforePurchase, docBalanceAfterPurchase);
    //     assertEq(RbtcBalanceAfterPurchase, RbtcBalanceBeforePurchase);
    // }

    // function testBatchPurchasesOneUser() external {
    //     this.testCreateSeveralDcaSchedules();
    //     uint256 prevDocTokenHandlerBalance = address(docTokenHandler).balance;
    //     vm.prank(USER);
    //     uint256 userAccumulatedRbtcPrev = docTokenHandler.getAccumulatedRbtcBalance();
    //     vm.prank(OWNER);
    //     address user = dcaManager.getUsers()[0]; // Only one user in this test, but several schedules
    //     // uint256 numOfPurchases = dcaManager.ownerGetUsersDcaSchedules(user, address(mockDocToken)).length;
    //     address[] memory users = new address[](NUM_OF_SCHEDULES);
    //     uint256[] memory scheduleIndexes = new uint256[](NUM_OF_SCHEDULES);
    //     uint256[] memory purchaseAmounts = new uint256[](NUM_OF_SCHEDULES);
    //     uint256[] memory purchasePeriods = new uint256[](NUM_OF_SCHEDULES);

    //     uint256 totalNetPurchaseAmount;

    //     for (uint8 i; i < NUM_OF_SCHEDULES; ++i) { 
    //         uint256 scheduleIndex = i;
    //         vm.startPrank(USER);
    //         uint256 schedulePurchaseAmount = dcaManager.getSchedulePurchaseAmount(address(mockDocToken), scheduleIndex);
    //         uint256 schedulePurchasePeriod = dcaManager.getSchedulePurchasePeriod(address(mockDocToken), scheduleIndex);
    //         vm.stopPrank();
    //         uint256 fee = feeCalculator.calculateFee(schedulePurchaseAmount, schedulePurchasePeriod);
    //         totalNetPurchaseAmount += schedulePurchaseAmount - fee;
            
    //         users[i] = user;
    //         scheduleIndexes[i] = i;
    //         vm.startPrank(OWNER);
    //         purchaseAmounts[i] = dcaManager.ownerGetUsersDcaSchedules(users[0], address(mockDocToken))[i].purchaseAmount;
    //         purchasePeriods[i] = dcaManager.ownerGetUsersDcaSchedules(users[0], address(mockDocToken))[i].purchasePeriod;
    //         vm.stopPrank();
    //     }
    //     for (uint8 i; i < NUM_OF_SCHEDULES; ++i) { 
    //         vm.expectEmit(false, false, false, false);
    //         emit TokenHandler__RbtcBought(USER, address(mockDocToken), 0, 0); // Never mind the actual values on this test
    //     }
    //     vm.expectEmit(true, true, true, false);
    //     emit TokenHandler__SuccessfulRbtcBatchPurchase(address(mockDocToken), totalNetPurchaseAmount / BTC_PRICE, totalNetPurchaseAmount);
    //     vm.prank(OWNER);
    //     dcaManager.batchBuyRbtc(users, address(mockDocToken), scheduleIndexes, purchaseAmounts, purchasePeriods);

    //     uint256 postDocTokenHandlerBalance = address(docTokenHandler).balance;

    //     // The balance of the DOC token handler contract gets incremented in exactly the purchased amount of rBTC
    //     assertEq(postDocTokenHandlerBalance - prevDocTokenHandlerBalance, totalNetPurchaseAmount / BTC_PRICE); 

    //     vm.prank(USER);
    //     uint256 userAccumulatedRbtcPost = docTokenHandler.getAccumulatedRbtcBalance();
    //     // The user's balance is also equal (since we're batching the purchases of 5 schedules but only one user)
    //     assertEq(userAccumulatedRbtcPost - userAccumulatedRbtcPrev, totalNetPurchaseAmount / BTC_PRICE); 

    //     vm.warp(block.timestamp + 5 weeks); // warp to a time far in the future so all schedules are long due for a new purchase
    //     vm.prank(OWNER);
    //     dcaManager.batchBuyRbtc(users, address(mockDocToken), scheduleIndexes, purchaseAmounts, purchasePeriods);
    //     uint256 postDocTokenHandlerBalance2 = address(docTokenHandler).balance;
    //     // After a second purchase, we have the same increment
    //     assertEq(postDocTokenHandlerBalance2 - postDocTokenHandlerBalance, totalNetPurchaseAmount / BTC_PRICE); 
        

    // }
// }