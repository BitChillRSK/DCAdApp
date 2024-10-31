// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../src/Test.sol";
import {Vm, VmSafe} from "../src/Vm.sol";

contract VmTest is Test {
    // This test ensures that functions are never accidentally removed from a Vm interface, or
    // inadvertently moved between Vm and VmSafe. This test must be updated each time a function is
    // added to or removed from Vm or VmSafe.
    function test_interfaceId() public {
        assertEq(type(VmSafe).interfaceId, bytes4(0x01ec102d), "VmSafe");
        assertEq(type(Vm).interfaceId, bytes4(0xa63eed6b), "Vm");
    }
}