//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
import "../Constants.sol";

contract DocHandlerMocTest is DcaDappTest {
    function setUp() public override {
        super.setUp();
    }

    ////////////////////////////
    ///// Settings tests ///////
    ////////////////////////////

    function testDocHandlerSupportsInterface() external {
        assertEq(docHandler.supportsInterface(type(ITokenHandler).interfaceId), true);
    }

    function testDocHandlerModifyMinPurchaseAmount() external {
        vm.prank(OWNER);
        docHandler.modifyMinPurchaseAmount(1000);
        uint256 newPurchaseAmount = docHandler.getMinPurchaseAmount();
        assertEq(newPurchaseAmount, 1000);
    }

    function testDocHandlerSetFeeRateParams() external {
        vm.prank(OWNER);
        docHandler.setFeeRateParams(5, 5, 5, 5);
        assertEq(docHandler.getMinFeeRate(), 5);
        assertEq(docHandler.getMaxFeeRate(), 5);
        assertEq(docHandler.getMinAnnualAmount(), 5);
        assertEq(docHandler.getMaxAnnualAmount(), 5);
    }

    function testDocHandlerSetFeeCollectorAddress() external {
        address newFeeCollector = makeAddr("newFeeCollector");
        vm.prank(OWNER);
        docHandler.setFeeCollectorAddress(newFeeCollector);
        assertEq(docHandler.getFeeCollectorAddress(), newFeeCollector);
    }
}