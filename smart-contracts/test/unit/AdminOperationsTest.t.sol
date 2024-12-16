//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DcaDappTest} from "./DcaDappTest.t.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
import {DocTokenHandler} from "../../src/DocTokenHandler.sol";
import {IAdminOperations} from "../../src/interfaces/IAdminOperations.sol";
import "./TestsHelper.t.sol";

contract AdminOperationsTest is DcaDappTest {
    function setUp() public override {
        super.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                         ADMIN OPERATIONS TESTS
    //////////////////////////////////////////////////////////////*/
    function testUpdateTokenHandlerMustSupportInterface() external {
        vm.startBroadcast();
        DummyERC165Contract dummyERC165Contract = new DummyERC165Contract();
        vm.stopBroadcast();
        bytes memory encodedRevert = abi.encodeWithSelector(
            IAdminOperations.AdminOperations__ContractIsNotTokenHandler.selector, address(dummyERC165Contract)
        );

        vm.expectRevert(encodedRevert);
        // vm.prank(OWNER);
        vm.prank(ADMIN);
        adminOperations.assignOrUpdateTokenHandler(address(mockDocToken), address(dummyERC165Contract));

        vm.expectRevert();
        // vm.prank(OWNER);
        vm.prank(ADMIN);
        adminOperations.assignOrUpdateTokenHandler(address(mockDocToken), address(dcaManager));
    }

    function testUpdateTokenHandlerFailsIfAddressIsEoa() external {
        address dummyAddress = makeAddr("dummyAddress");
        bytes memory encodedRevert =
            abi.encodeWithSelector(IAdminOperations.AdminOperations__EoaCannotBeHandler.selector, dummyAddress);
        vm.expectRevert(encodedRevert);
        // vm.prank(OWNER);
        vm.prank(ADMIN);
        adminOperations.assignOrUpdateTokenHandler(address(mockDocToken), dummyAddress);
    }

    function testTokenHandlerUpdated() external {
        address prevDocTokenHandler = adminOperations.getTokenHandler(address(mockDocToken));
        vm.startBroadcast();
        DocTokenHandler newDocTokenHandler = new DocTokenHandler(
            address(dcaManager),
            address(mockDocToken),
            address(mockKdocToken),
            MIN_PURCHASE_AMOUNT,
            address(mockMocProxy),
            FEE_COLLECTOR,
            MIN_FEE_RATE,
            MAX_FEE_RATE,
            MIN_ANNUAL_AMOUNT,
            MAX_ANNUAL_AMOUNT,
            DOC_YIELDS_INTEREST
        );
        vm.stopBroadcast();
        assert(prevDocTokenHandler != address(newDocTokenHandler));
        // vm.prank(OWNER);
        vm.prank(ADMIN);
        adminOperations.assignOrUpdateTokenHandler(address(mockDocToken), address(newDocTokenHandler));
        assertEq(adminOperations.getTokenHandler(address(mockDocToken)), address(newDocTokenHandler));
    }
}
