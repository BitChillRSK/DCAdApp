//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {IDcaManager} from "../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../src/interfaces/ITokenHandler.sol";
import {IDocTokenHandler} from "../src/interfaces/IDocTokenHandler.sol";
import {IAdminOperations} from "../src/interfaces/IAdminOperations.sol";
import {console} from "forge-std/Test.sol";

contract ErrorLogger is Script {

    function run() external {
        // Array of all error selectors in the IDcaManager interface
        bytes4[] memory errorSelectors = new bytes4[](14);
        errorSelectors[0] = IDcaManager.DcaManager__TokenNotAccepted.selector;
        errorSelectors[1] = IDcaManager.DcaManager__DepositAmountMustBeGreaterThanZero.selector;
        errorSelectors[2] = IDcaManager.DcaManager__WithdrawalAmountMustBeGreaterThanZero.selector;
        errorSelectors[3] = IDcaManager.DcaManager__WithdrawalAmountExceedsBalance.selector;
        errorSelectors[4] = IDcaManager.DcaManager__PurchaseAmountMustBeGreaterThanMinimum.selector;
        errorSelectors[5] = IDcaManager.DcaManager__PurchasePeriodMustBeGreaterThanMin.selector;
        errorSelectors[6] = IDcaManager.DcaManager__PurchaseAmountMustBeLowerThanHalfOfBalance.selector;
        errorSelectors[7] = IDcaManager.DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed.selector;
        errorSelectors[8] = IDcaManager.DcaManager__DcaScheduleDoesNotExist.selector;
        errorSelectors[9] = IDcaManager.DcaManager__InexistentSchedule.selector;
        errorSelectors[10] = IDcaManager.DcaManager__ScheduleBalanceNotEnoughForPurchase.selector;
        errorSelectors[11] = IDcaManager.DcaManager__BatchPurchaseArraysLengthMismatch.selector;
        errorSelectors[12] = IDcaManager.DcaManager__EmptyBatchPurchaseArrays.selector;
        errorSelectors[13] = IDcaManager.DcaManager__TokenDoesNotYieldInterest.selector;

        string[] memory errorNames = new string[](14);
        errorNames[0] = "DcaManager__TokenNotAccepted";
        errorNames[1] = "DcaManager__DepositAmountMustBeGreaterThanZero";
        errorNames[2] = "DcaManager__WithdrawalAmountMustBeGreaterThanZero";
        errorNames[3] = "DcaManager__WithdrawalAmountExceedsBalance";
        errorNames[4] = "DcaManager__PurchaseAmountMustBeGreaterThanMinimum";
        errorNames[5] = "DcaManager__PurchasePeriodMustBeGreaterThanMin";
        errorNames[6] = "DcaManager__PurchaseAmountMustBeLowerThanHalfOfBalance";
        errorNames[7] = "DcaManager__CannotBuyIfPurchasePeriodHasNotElapsed";
        errorNames[8] = "DcaManager__DcaScheduleDoesNotExist";
        errorNames[9] = "DcaManager__InexistentSchedule";
        errorNames[10] = "DcaManager__ScheduleBalanceNotEnoughForPurchase";
        errorNames[11] = "DcaManager__BatchPurchaseArraysLengthMismatch";
        errorNames[12] = "DcaManager__EmptyBatchPurchaseArrays";
        errorNames[13] = "DcaManager__TokenDoesNotYieldInterest";

        // Log each error name and its selector
        for (uint256 i = 0; i < errorSelectors.length; i++) {
            console.log(errorNames[i]);
            console.logBytes4(errorSelectors[i]);
        }
    }
}
