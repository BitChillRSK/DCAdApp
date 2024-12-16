//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";

contract DcaScheduleTest is DcaDappTest {
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////
    /// DcaSchedule tests  //////////
    /////////////////////////////////

    function testCreateDcaSchedule() external {
        vm.startPrank(USER);
        uint256 scheduleIndex = dcaManager.getMyDcaSchedules(address(mockDocToken)).length;
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
        bytes32 scheduleId = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        vm.expectEmit(true, true, true, true);
        emit DcaManager__DcaScheduleCreated(
            USER, address(mockDocToken), scheduleId, DOC_TO_DEPOSIT, DOC_TO_SPEND, MIN_PURCHASE_PERIOD
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        uint256 scheduleBalanceAfterDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
        assertEq(DOC_TO_DEPOSIT, scheduleBalanceAfterDeposit);
        assertEq(DOC_TO_SPEND, dcaManager.getSchedulePurchaseAmount(address(mockDocToken), scheduleIndex));
        assertEq(MIN_PURCHASE_PERIOD, dcaManager.getSchedulePurchasePeriod(address(mockDocToken), scheduleIndex));
        vm.stopPrank();
    }

    function testDcaScheduleIdsDontCollide() external {
        vm.startPrank(USER);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
        bytes32 scheduleId = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        console.log("First timestamp", block.timestamp);
        vm.expectEmit(true, true, true, true);
        emit DcaManager__DcaScheduleCreated(
            USER, address(mockDocToken), scheduleId, DOC_TO_DEPOSIT / 2, DOC_TO_SPEND, MIN_PURCHASE_PERIOD
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT / 2, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        bytes32 scheduleId2 = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        console.log("Second timestamp", block.timestamp);
        vm.expectEmit(true, true, true, true);
        emit DcaManager__DcaScheduleCreated(
            USER, address(mockDocToken), scheduleId2, DOC_TO_DEPOSIT / 2, DOC_TO_SPEND, MIN_PURCHASE_PERIOD
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT / 2, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        assert(scheduleId != scheduleId2);
        vm.stopPrank();
    }

    function testUpdateDcaSchedule() external {
        uint256 newPurchaseAmount = DOC_TO_SPEND / 2;
        uint256 newPurchasePeriod = MIN_PURCHASE_PERIOD * 10;
        uint256 extraDocToDeposit = DOC_TO_DEPOSIT / 3;
        vm.startPrank(USER);
        uint256 userBalanceBeforeDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        mockDocToken.approve(address(docTokenHandler), extraDocToDeposit);
        bytes32 scheduleId = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length - 1)
        );
        vm.expectEmit(true, true, true, true);
        emit DcaManager__DcaScheduleUpdated(
            USER, address(mockDocToken), scheduleId, extraDocToDeposit, newPurchaseAmount, newPurchasePeriod
        );
        dcaManager.updateDcaSchedule(
            address(mockDocToken), SCHEDULE_INDEX, extraDocToDeposit, newPurchaseAmount, newPurchasePeriod
        );
        uint256 userBalanceAfterDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        assertEq(extraDocToDeposit, userBalanceAfterDeposit - userBalanceBeforeDeposit);
        assertEq(newPurchaseAmount, dcaManager.getSchedulePurchaseAmount(address(mockDocToken), SCHEDULE_INDEX));
        assertEq(newPurchasePeriod, dcaManager.getSchedulePurchasePeriod(address(mockDocToken), SCHEDULE_INDEX));
        vm.stopPrank();
    }

    function testDeleteDcaSchedule() external {
        vm.startPrank(USER);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT * 5);
        // Create two schedules in different blocks
        bytes32 scheduleId = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT * 2, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        vm.warp(block.timestamp + 1 minutes);
        bytes32 scheduleId2 = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT * 3, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        console.log("scheduleId is", vm.toString(scheduleId));
        console.log("scheduleId2 is", vm.toString(scheduleId2));
        // Delete one
        dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId);
        // Check that there are two (the one created in setUp() and the second one created in this test)
        assertEq(dcaManager.getMyDcaSchedules(address(mockDocToken)).length, 2);
        // Check that the deleted one was the first one created in this test and its place was taken by the second one
        assertEq(dcaManager.getMyDcaSchedules(address(mockDocToken))[1].scheduleId, scheduleId2);
        vm.stopPrank();
    }

    function testDeleteTwoDcaSchedules() public {
        vm.startPrank(USER);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT * 5);
        // Create two schedules in different blocks
        bytes32 scheduleId = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT * 2, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        vm.warp(block.timestamp + 1 minutes);
        bytes32 scheduleId2 = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT * 3, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        console.log("scheduleId is", vm.toString(scheduleId));
        console.log(vm.toString(dcaManager.getMyDcaSchedules(address(mockDocToken))[1].scheduleId));
        console.log("scheduleId 2 is", vm.toString(scheduleId2));
        console.log(vm.toString(dcaManager.getMyDcaSchedules(address(mockDocToken))[2].scheduleId));
        // Delete one
        dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId);
        // Delete the second one passing the same index, since the first one was already deleted
        dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId2);
        // Check only the schedule created in setUp() remains
        assertEq(dcaManager.getMyDcaSchedules(address(mockDocToken)).length, 1);
        // dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId);
        vm.stopPrank();
    }

    /**
     * @notice This was just a test to compare options in terms of gas consumptio
     */
    function testDeleteSeveraldcaSchedules() external {
        super.createSeveralDcaSchedules();
        vm.startPrank(USER);
        // for (uint256 i = 0; i < NUM_OF_SCHEDULES; ++i) {
        //     bytes32 scheduleId = keccak256(abi.encodePacked(USER, block.timestamp, NUM_OF_SCHEDULES - 1 - i));
        //     dcaManager.deleteDcaSchedule(address(mockDocToken), NUM_OF_SCHEDULES - 1 - i, scheduleId);
        // }
        for (uint256 i = NUM_OF_SCHEDULES; i > 0; --i) {
            bytes32 scheduleId = keccak256(abi.encodePacked(USER, block.timestamp, i - 1));
            dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId);
        }
        vm.stopPrank();
    }

    /**
     * @notice this test shows that a transaction that aims to delete the last schedule in the array after another schedule has been deleted in a previous transaction
     * reverts if both transactions have been included in the same block // this has to be prevented in the front end
     */
    function testCannotDeleteLastDcaScheduleInTheSameBlock() external {
        vm.startPrank(USER);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT * 5);
        // Create two schedules in different blocks
        bytes32 scheduleId = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT * 2, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        vm.warp(block.timestamp + 1 minutes);
        bytes32 scheduleId2 = keccak256(
            abi.encodePacked(USER, block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        dcaManager.createDcaSchedule(address(mockDocToken), DOC_TO_DEPOSIT * 3, DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        console.log("scheduleId is", vm.toString(scheduleId));
        console.log(vm.toString(dcaManager.getMyDcaSchedules(address(mockDocToken))[1].scheduleId));
        console.log("scheduleId 2 is", vm.toString(scheduleId2));
        console.log(vm.toString(dcaManager.getMyDcaSchedules(address(mockDocToken))[2].scheduleId));
        // Delete one
        dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId);
        // Deleting the second one fails, because when the first one was deleted, the second one was moved to its index
        dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId2);
        vm.stopPrank();
    }

    function testCreateSeveralDcaSchedules() external {
        // vm.startPrank(USER);
        // mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
        // uint256 docToDeposit = DOC_TO_DEPOSIT / NUM_OF_SCHEDULES;
        // uint256 purchaseAmount = DOC_TO_SPEND / NUM_OF_SCHEDULES;
        // for (uint256 i = 1; i < NUM_OF_SCHEDULES; ++i) { // Start from 1 since schedule 0 is created in setUp
        //     uint256 scheduleIndex = SCHEDULE_INDEX + i;
        //     uint256 purchasePeriod = MIN_PURCHASE_PERIOD + i * 5 days;
        //     uint256 userBalanceBeforeDeposit;
        //     if (dcaManager.getMyDcaSchedules(address(mockDocToken)).length > scheduleIndex) {
        //         userBalanceBeforeDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
        //     } else {
        //         userBalanceBeforeDeposit = 0;
        //     }
        //     vm.expectEmit(true, true, true, true);
        //     emit DcaManager__DcaScheduleCreated(
        //         USER, address(mockDocToken), scheduleIndex, docToDeposit, purchaseAmount, purchasePeriod
        //     );
        //     dcaManager.createDcaSchedule(
        //         address(mockDocToken), docToDeposit, purchaseAmount, purchasePeriod
        //     );
        //     uint256 userBalanceAfterDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
        //     assertEq(docToDeposit, userBalanceAfterDeposit - userBalanceBeforeDeposit);
        //     assertEq(purchaseAmount, dcaManager.getSchedulePurchaseAmount(address(mockDocToken), scheduleIndex));
        //     assertEq(purchasePeriod, dcaManager.getSchedulePurchasePeriod(address(mockDocToken), scheduleIndex));
        // }
        // vm.stopPrank();

        super.createSeveralDcaSchedules();
    }

    function testCannotUpdateInexistentSchedule() external {
        vm.startPrank(USER);
        vm.expectRevert(IDcaManager.DcaManager__InexistentScheduleIndex.selector);
        dcaManager.depositToken(address(mockDocToken), SCHEDULE_INDEX + 1, DOC_TO_DEPOSIT);
        vm.expectRevert(IDcaManager.DcaManager__InexistentScheduleIndex.selector);
        dcaManager.setPurchaseAmount(address(mockDocToken), SCHEDULE_INDEX + 1, DOC_TO_SPEND);
        vm.expectRevert(IDcaManager.DcaManager__InexistentScheduleIndex.selector);
        dcaManager.setPurchaseAmount(address(mockDocToken), SCHEDULE_INDEX + 1, MIN_PURCHASE_PERIOD);
        vm.expectRevert(IDcaManager.DcaManager__InexistentScheduleIndex.selector);
        dcaManager.updateDcaSchedule(address(mockDocToken), 1, 1, 1, 1);
        vm.stopPrank();
    }

    function testCannotConsultInexistentSchedule() external {
        vm.startPrank(USER);
        vm.expectRevert(IDcaManager.DcaManager__InexistentScheduleIndex.selector);
        dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX + 1);
        vm.expectRevert(IDcaManager.DcaManager__InexistentScheduleIndex.selector);
        dcaManager.getSchedulePurchaseAmount(address(mockDocToken), SCHEDULE_INDEX + 1);
        vm.expectRevert(IDcaManager.DcaManager__InexistentScheduleIndex.selector);
        dcaManager.getSchedulePurchasePeriod(address(mockDocToken), SCHEDULE_INDEX + 1);
        vm.stopPrank();
    }

    function testCannotDeleteInexistentSchedule() external {
        bytes32 scheduleId = keccak256(
            abi.encodePacked(USER, block.timestamp + 1, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
        );
        vm.expectRevert(IDcaManager.DcaManager__InexistentScheduleId.selector);
        vm.prank(USER);
        dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId);
    }

    // function testScheduleIndexAndIdMismatchReverts() external {
    //     bytes32 scheduleId = keccak256(
    //         abi.encodePacked("dummyStuff", block.timestamp, dcaManager.getMyDcaSchedules(address(mockDocToken)).length)
    //     );
    //     vm.expectRevert(IDcaManager.DcaManager__ScheduleIdAndIndexMismatch.selector);
    //     vm.prank(USER);
    //     dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleId);
    // }
}
