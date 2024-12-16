//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";

contract ModifiersTest is DcaDappTest {

    function setUp() public override {
        super.setUp();
    }
    
    /*//////////////////////////////////////////////////////////////
                            ONLYOWNER TESTS
    //////////////////////////////////////////////////////////////*/
    function testonlyOwnerCanSetAdminOperations() external {
        address adminOperationsBefore = dcaManager.getAdminOperationsAddress();
        bytes memory encodedRevert = abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER);
        vm.expectRevert(encodedRevert);
        vm.prank(USER); // User can't
        dcaManager.setAdminOperations(address(dcaManager)); // dummy address, e.g. that of DcaManager
        address adminOperationsAfter = dcaManager.getAdminOperationsAddress();
        assertEq(adminOperationsBefore, adminOperationsAfter);
        vm.prank(OWNER); // Owner can
        dcaManager.setAdminOperations(address(dcaManager));
        adminOperationsAfter = dcaManager.getAdminOperationsAddress();
        assertEq(adminOperationsAfter, address(dcaManager));
    }

    function testonlyOwnerCanModifyMinPurchasePeriod() external {
        uint256 newMinPurchasePeriod = 2 days;
        uint256 minPurchasePeriodBefore = dcaManager.getMinPurchasePeriod();
        bytes memory encodedRevert = abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER);
        vm.expectRevert(encodedRevert);
        vm.prank(USER); // User can't
        dcaManager.modifyMinPurchasePeriod(newMinPurchasePeriod); // dummy address, e.g. that of DcaManager
        uint256 minPurchasePeriodAfter = dcaManager.getMinPurchasePeriod();
        assertEq(minPurchasePeriodBefore, minPurchasePeriodAfter);
        vm.prank(OWNER); // Owner can
        dcaManager.modifyMinPurchasePeriod(newMinPurchasePeriod);
        minPurchasePeriodAfter = dcaManager.getMinPurchasePeriod();
        assertEq(minPurchasePeriodAfter, newMinPurchasePeriod);
    }
}