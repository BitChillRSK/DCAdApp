//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";

contract DocWithdrawalTest is DcaDappTest {

    function setUp() public override {
        super.setUp();
    }
    
    ////////////////////////////
    /// DOC Withdrawal tests ///
    ////////////////////////////
    function testDocWithdrawal() external {
        super.withdrawDoc(); 
    }

    function testCannotWithdrawZeroDoc() external {
        vm.startPrank(USER);
        vm.expectRevert(IDcaManager.DcaManager__WithdrawalAmountMustBeGreaterThanZero.selector);
        dcaManager.withdrawToken(address(mockDocToken), SCHEDULE_INDEX, 0);
        vm.stopPrank();
    }

    function testTokenWithdrawalRevertsIfAmountExceedsBalance() external {
        vm.startPrank(USER);
        bytes memory encodedRevert = abi.encodeWithSelector(
            IDcaManager.DcaManager__WithdrawalAmountExceedsBalance.selector,
            address(mockDocToken),
            USER_TOTAL_DOC,
            DOC_TO_DEPOSIT
        );
        vm.expectRevert(encodedRevert);
        dcaManager.withdrawToken(address(mockDocToken), SCHEDULE_INDEX, USER_TOTAL_DOC);
        vm.stopPrank();
    }
}