//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";

contract DcaConfigurationTest is DcaDappTest {

    function setUp() public override {
        super.setUp();
    }
    
    ///////////////////////////////
    /// DCA configuration tests ///
    ///////////////////////////////
    function testSetPurchaseAmount() external {
        vm.startPrank(USER);
        dcaManager.setPurchaseAmount(address(mockDocToken), SCHEDULE_INDEX, DOC_TO_SPEND);
        assertEq(DOC_TO_SPEND, dcaManager.getSchedulePurchaseAmount(address(mockDocToken), SCHEDULE_INDEX));
        vm.stopPrank();
    }

    function testSetPurchasePeriod() external {
        vm.startPrank(USER);
        dcaManager.setPurchasePeriod(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_PERIOD);
        assertEq(MIN_PURCHASE_PERIOD, dcaManager.getSchedulePurchasePeriod(address(mockDocToken), SCHEDULE_INDEX));
        vm.stopPrank();
    }

    function testPurchaseAmountCannotBeMoreThanHalfBalance() external {
        vm.expectRevert(IDcaManager.DcaManager__PurchaseAmountMustBeLowerThanHalfOfBalance.selector);
        vm.prank(USER);
        dcaManager.setPurchaseAmount(address(mockDocToken), SCHEDULE_INDEX, DOC_TO_DEPOSIT / 2 + 1);
    }

    function testPurchaseAmountMustBeGreaterThanMin() external {
        bytes memory encodedRevert = abi.encodeWithSelector(
            IDcaManager.DcaManager__PurchaseAmountMustBeGreaterThanMinimum.selector,
            address(mockDocToken)
        );
        vm.expectRevert(encodedRevert);
        vm.prank(USER);
        dcaManager.setPurchaseAmount(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_AMOUNT - 1);
    }

    function testPurchasePeriodMustBeGreaterThanMin() external {
        vm.expectRevert(IDcaManager.DcaManager__PurchasePeriodMustBeGreaterThanMin.selector);
        vm.prank(USER);
        dcaManager.setPurchasePeriod(address(mockDocToken), SCHEDULE_INDEX, MIN_PURCHASE_PERIOD - 1);
    }
}