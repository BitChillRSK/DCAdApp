//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
import "../Constants.sol";

contract DocTokenHandlerTest is DcaDappTest {

    function setUp() public override {
        super.setUp();
    }
    
    ////////////////////////////
    ///// Settings tests ///////
    ////////////////////////////

    function testSupportsInterface() external {
        assertEq(docTokenHandler.supportsInterface(type(ITokenHandler).interfaceId), true);
    }

    function testModifyMinPurchaseAmount() external {
        vm.prank(OWNER);
        docTokenHandler.modifyMinPurchaseAmount(1000);
        uint256 newPurchaseAmount = docTokenHandler.getMinPurchaseAmount();
        assertEq(newPurchaseAmount, 1000);
    }

    function testSetFeeRateParams() external {
        vm.prank(OWNER);
        docTokenHandler.setFeeRateParams(5,5,5,5);
        assertEq(docTokenHandler.getMinFeeRate(), 5);
        assertEq(docTokenHandler.getMaxFeeRate(), 5);
        assertEq(docTokenHandler.getMinAnnualAmount(), 5);
        assertEq(docTokenHandler.getMaxAnnualAmount(), 5);
    }

    function testSetFeeCollectorAddress() external {
        address newFeeCollector = makeAddr("newFeeCollector");
        vm.prank(OWNER);
        docTokenHandler.setFeeCollectorAddress(newFeeCollector);
        assertEq(docTokenHandler.getFeeCollectorAddress(), newFeeCollector);
    }
}