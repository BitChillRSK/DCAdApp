//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";

contract DocDepositTest is DcaDappTest {
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////
    /// DOC deposit tests ///
    /////////////////////////
    function testDocDeposit() external {
        (uint256 userBalanceAfterDeposit, uint256 userBalanceBeforeDeposit) = super.depositDoc();
        assertEq(DOC_TO_DEPOSIT, userBalanceAfterDeposit - userBalanceBeforeDeposit);
    }

    function testCannotDepositZeroDoc() external {
        vm.startPrank(USER);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
        vm.expectRevert(IDcaManager.DcaManager__DepositAmountMustBeGreaterThanZero.selector);
        dcaManager.depositToken(address(mockDocToken), SCHEDULE_INDEX, 0);
        vm.stopPrank();
    }

    function testDepositRevertsIfDocNotApproved() external {
        vm.startPrank(USER);
        bytes memory encodedRevert = abi.encodeWithSelector(
            ITokenHandler.TokenHandler__InsufficientTokenAllowance.selector, address(mockDocToken)
        );
        vm.expectRevert(encodedRevert);
        dcaManager.depositToken(address(mockDocToken), SCHEDULE_INDEX, DOC_TO_DEPOSIT);
        vm.stopPrank();
    }
}
