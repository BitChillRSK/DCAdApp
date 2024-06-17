//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
import "../Constants.sol";

contract DocLendingTest is DcaDappTest {

    function setUp() public override {
        super.setUp();
    }
    
    ////////////////////////////
    ///// DOC Lending tests ////
    ////////////////////////////
    function testDocDepositedIsLent() external {
        super.depositDoc();
        assertEq(mockDocToken.balanceOf(address(docTokenHandler)), 0); // DOC balance in handler contract is 0 because DOC is lent to Tropykus
        assertEq(mockDocToken.balanceOf(address(mockKdocToken)), 2 * DOC_TO_DEPOSIT); // Twice the DOC to deposit since a schedule is created in setUp()
    }

    function testDocDepositIncreasesKdocBalance() external {
        uint256 prevKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        super.depositDoc();
        uint256 postKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        assertEq(mockKdocToken.balanceOf(address(docTokenHandler)), 2 * DOC_TO_DEPOSIT * mockKdocToken.exchangeRateStored() / 1E18);
        assertEq(postKdocBalance - prevKdocBalance, DOC_TO_DEPOSIT * mockKdocToken.exchangeRateStored() / 1E18);
    }

    function testDocWithdrawalRedeemsKdoc() external {        
        uint256 prevKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        super.withdrawDoc();
        uint256 postKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        assertEq(mockKdocToken.balanceOf(address(docTokenHandler)), 0);
        assertEq(prevKdocBalance - postKdocBalance, DOC_TO_DEPOSIT * mockKdocToken.exchangeRateStored() / 1E18);
    }

    function testRbtcPurchaseRedeemsKdoc() external {      
        uint256 prevKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        super.makeSinglePurchase();
        uint256 postKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        assertEq(mockKdocToken.balanceOf(address(docTokenHandler)), (DOC_TO_DEPOSIT - DOC_TO_SPEND) * mockKdocToken.exchangeRateStored() / 1E18);
        assertEq(prevKdocBalance - postKdocBalance, DOC_TO_SPEND * mockKdocToken.exchangeRateStored() / 1E18);
    }

    function testSeveralRbtcPurchasesRedeemKdoc() external {  // This just for one user, for many users this will get tested in invariant tests  
        super.createSeveralDcaSchedules();    
        uint256 prevKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        console.log("kDOC balance before purchases", prevKdocBalance);
        super.makeSeveralPurchasesWithSeveralSchedules();
        uint256 postKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        console.log("kDOC balance after purchases", postKdocBalance);
        assertEq(prevKdocBalance - postKdocBalance, NUM_OF_SCHEDULES * DOC_TO_SPEND * mockKdocToken.exchangeRateStored() / 1E18);
        assertEq(mockKdocToken.balanceOf(address(docTokenHandler)), (DOC_TO_DEPOSIT - NUM_OF_SCHEDULES * DOC_TO_SPEND) * mockKdocToken.exchangeRateStored() / 1E18);
    }

    function testRbtcBatchPurchaseRedeemsKdoc() external {// This just for one user, for many users this will get tested in invariant tests  
        super.createSeveralDcaSchedules(); // This creates NUM_OF_SCHEDULES schedules with purchaseAmount = DOC_TO_SPEND / NUM_OF_SCHEDULES
        uint256 prevKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        super.makeBatchPurchasesOneUser(); // Batched purchases add up to an amount of DOC_TO_SPEND, this function makes two batch purchases
        uint256 postKdocBalance = docTokenHandler.getUsersKdocBalance(USER);
        assertEq(prevKdocBalance - postKdocBalance, 2 * DOC_TO_SPEND * mockKdocToken.exchangeRateStored() / 1E18); 
        assertEq(mockKdocToken.balanceOf(address(docTokenHandler)), (DOC_TO_DEPOSIT - 2 * DOC_TO_SPEND) * mockKdocToken.exchangeRateStored() / 1E18);
    }
}