// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Vm} from "forge-std/Vm.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "src/interfaces/IDcaManager.sol";
import {IPurchaseRbtc} from "src/interfaces/IPurchaseRbtc.sol";
import "../Constants.sol";
import {scheduleAt, scheduleIdAt, scheduleCount} from "test/utils/ScheduleAt.sol";

/**
 * @notice Coverage for the swapper-activated, five-block batch preparation window.
 */
contract ProtectedPurchaseWindowTest is DcaDappTest {
    event DcaManager__ProtectedPurchaseWindowActivated(
        address indexed swapper, uint256 userMutationsAllowedFromBlock
    );

    function testSwapperActivatesFiveBlockWindowAndEventIndexesOnlySwapper() external {
        assertEq(dcaManager.getUserMutationsAllowedFromBlock(), 0);
        uint256 expectedAllowedFromBlock = block.number + 5;

        vm.recordLogs();
        vm.prank(SWAPPER);
        dcaManager.activateProtectedPurchaseWindow();

        assertEq(dcaManager.getUserMutationsAllowedFromBlock(), expectedAllowedFromBlock);
        bytes32 sig = DcaManager__ProtectedPurchaseWindowActivated.selector;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool found;
        for (uint256 i; i < logs.length; ++i) {
            if (logs[i].topics[0] != sig) continue;
            assertEq(logs[i].topics.length, 2, "only the swapper address is indexed");
            assertEq(address(uint160(uint256(logs[i].topics[1]))), SWAPPER);
            assertEq(abi.decode(logs[i].data, (uint256)), expectedAllowedFromBlock);
            found = true;
        }
        assertTrue(found, "activation event not emitted");
    }

    function testOnlyCurrentSwapperCanActivate() external {
        vm.expectRevert(abi.encodeWithSelector(IDcaManager.DcaManager__UnauthorizedSwapper.selector, USER));
        vm.prank(USER);
        dcaManager.activateProtectedPurchaseWindow();

        vm.prank(OWNER);
        operationsAdmin.revokeSwapper(SWAPPER);
        vm.expectRevert(abi.encodeWithSelector(IDcaManager.DcaManager__UnauthorizedSwapper.selector, SWAPPER));
        vm.prank(SWAPPER);
        dcaManager.activateProtectedPurchaseWindow();
    }

    function testEveryBatchInvalidatingUserMutationIsLockedThroughFourthFollowingBlock() external {
        uint64 scheduleId = _scheduleId();
        uint256 allowedFromBlock = _activateWindow();
        bytes memory expectedRevert =
            abi.encodeWithSelector(IDcaManager.DcaManager__UserMutationsLocked.selector, allowedFromBlock);

        _assertUserCallRevertsLocked(
            abi.encodeCall(IDcaManager.updatePurchaseAmount, (address(stablecoin), scheduleId, AMOUNT_TO_SPEND)),
            expectedRevert
        );

        vm.roll(allowedFromBlock - 1);
        _assertUserCallRevertsLocked(
            abi.encodeCall(IDcaManager.updatePurchasePeriod, (address(stablecoin), scheduleId, MIN_PURCHASE_PERIOD)),
            expectedRevert
        );
        _assertUserCallRevertsLocked(
            abi.encodeCall(IDcaManager.setSchedulePaused, (address(stablecoin), scheduleId, true)), expectedRevert
        );
        _assertUserCallRevertsLocked(
            abi.encodeCall(IDcaManager.deleteDcaSchedule, (address(stablecoin), scheduleId)), expectedRevert
        );
        _assertUserCallRevertsLocked(
            abi.encodeCall(IDcaManager.withdrawToken, (address(stablecoin), scheduleId, 1)), expectedRevert
        );
        _assertUserCallRevertsLocked(
            abi.encodeCall(IDcaManager.withdrawTokenAndInterest, (address(stablecoin), scheduleId, 1)),
            expectedRevert
        );

        address[] memory tokens = new address[](1);
        tokens[0] = address(stablecoin);
        uint256[] memory routeIndexes = new uint256[](1);
        routeIndexes[0] = s_routeIndex;
        _assertUserCallRevertsLocked(
            abi.encodeCall(IDcaManager.withdrawAllAccumulatedInterest, (tokens, routeIndexes)), expectedRevert
        );

        vm.roll(allowedFromBlock);
        vm.prank(USER);
        dcaManager.updatePurchaseAmount(address(stablecoin), scheduleId, AMOUNT_TO_SPEND);
    }

    function testActivationCannotBeRenewedOrExtended() external {
        vm.warp(100 days - 1);
        uint256 allowedFromBlock = _activateWindow();
        uint256 activationDay = block.timestamp / 1 days;

        vm.expectRevert(
            abi.encodeWithSelector(
                IDcaManager.DcaManager__ProtectedPurchaseWindowAlreadyActivated.selector, activationDay
            )
        );
        vm.prank(SWAPPER);
        dcaManager.activateProtectedPurchaseWindow();

        vm.warp(100 days);
        vm.expectRevert(
            abi.encodeWithSelector(IDcaManager.DcaManager__UserMutationsLocked.selector, allowedFromBlock)
        );
        vm.prank(SWAPPER);
        dcaManager.activateProtectedPurchaseWindow();

        vm.roll(allowedFromBlock);
        vm.prank(SWAPPER);
        dcaManager.activateProtectedPurchaseWindow();
        assertEq(dcaManager.getUserMutationsAllowedFromBlock(), allowedFromBlock + 5);
    }

    function testSameUtcDayCannotActivateAgainAfterExpiry() external {
        vm.warp(100 days + 1 hours);
        uint256 allowedFromBlock = _activateWindow();
        vm.roll(allowedFromBlock);

        uint256 utcDay = block.timestamp / 1 days;
        vm.expectRevert(
            abi.encodeWithSelector(IDcaManager.DcaManager__ProtectedPurchaseWindowAlreadyActivated.selector, utcDay)
        );
        vm.prank(SWAPPER);
        dcaManager.activateProtectedPurchaseWindow();
    }

    function testPreparedBatchPurchasesWhileOwnerMutationIsLocked() external {
        uint64 scheduleId = _scheduleId();
        uint256 balanceBefore = scheduleAt(dcaManager, USER, address(stablecoin), SCHEDULE_INDEX).tokenBalance;
        uint256 allowedFromBlock = _activateWindow();

        vm.expectRevert(
            abi.encodeWithSelector(IDcaManager.DcaManager__UserMutationsLocked.selector, allowedFromBlock)
        );
        vm.prank(USER);
        dcaManager.updatePurchaseAmount(address(stablecoin), scheduleId, AMOUNT_TO_SPEND * 2);

        buyRbtcOne(scheduleId);
        assertLt(scheduleAt(dcaManager, USER, address(stablecoin), SCHEDULE_INDEX).tokenBalance, balanceBefore);
    }

    function testUnrelatedUserActionsAndGovernanceStayOpen() external {
        if (block.chainid != ANVIL_CHAIN_ID) return;

        uint64 scheduleId = _scheduleId();
        _activateWindow();

        vm.startPrank(USER);
        stablecoin.approve(address(stablecoinHandler), type(uint256).max);
        dcaManager.depositToken(address(stablecoin), scheduleId, 1);
        dcaManager.createDcaSchedule(
            address(stablecoin), AMOUNT_TO_DEPOSIT, AMOUNT_TO_SPEND, MIN_PURCHASE_PERIOD, s_routeIndex
        );
        vm.stopPrank();
        assertEq(scheduleCount(dcaManager, USER, address(stablecoin)), 2);

        vm.prank(OWNER);
        dcaManager.modifyMinPurchasePeriod(2 days);
        assertEq(dcaManager.getMinPurchasePeriod(), 2 days);

        buyRbtcOne(scheduleId);
        assertGt(IPurchaseRbtc(address(stablecoinHandler)).getAccumulatedRbtcBalance(USER), 0);
        vm.prank(USER);
        dcaManager.withdrawRbtcFromTokenHandler(address(stablecoin), s_routeIndex);
    }

    function testInterestTopUpStaysOpen() external onlyLendingLane {
        updateExchangeRate(200 days);
        uint64 scheduleId = _scheduleId();
        uint256 accruedInterest = dcaManager.getInterestAccrued(USER, address(stablecoin), s_routeIndex);
        assertGt(accruedInterest, 0);

        uint256 slack = accruedInterest / 4;
        if (slack > AMOUNT_TO_SPEND / 10) slack = AMOUNT_TO_SPEND / 10;
        vm.prank(USER);
        dcaManager.withdrawToken(address(stablecoin), scheduleId, slack);

        _activateWindow();
        vm.prank(USER);
        dcaManager.topUpFromInterest(address(stablecoin), scheduleId, slack);
    }

    function _scheduleId() private view returns (uint64) {
        return scheduleIdAt(dcaManager, USER, address(stablecoin), SCHEDULE_INDEX);
    }

    function _activateWindow() private returns (uint256 allowedFromBlock) {
        allowedFromBlock = block.number + 5;
        vm.prank(SWAPPER);
        dcaManager.activateProtectedPurchaseWindow();
    }

    function _assertUserCallRevertsLocked(bytes memory callData, bytes memory expectedRevert) private {
        vm.prank(USER);
        (bool success, bytes memory returnData) = address(dcaManager).call(callData);
        assertFalse(success);
        assertEq(returnData, expectedRevert);
    }
}
