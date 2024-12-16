// //SPDX-License-Identifier: MIT

// pragma solidity 0.8.24;

// import {Test, console} from "forge-std/Test.sol";
// import {DcaDappTest} from "./DcaDappTest.t.sol";
// import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
// import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
// import "../Constants.sol";

// contract DocTokenHandlerDexTest is DcaDappTest {
//     string testEnv = vm.envString("TEST_ENV");

//     function setUp() public override {
//         if (keccak256(abi.encodePacked(testEnv)) != keccak256(abi.encodePacked("dexSwaps"))) {
//             return;
//         }
//         super.setUp();
//     }

//     ////////////////////////////
//     ///// Settings tests ///////
//     ////////////////////////////

//     function testDTHDSupportsInterface() external {
//         if (keccak256(abi.encodePacked(testEnv)) != keccak256(abi.encodePacked("dexSwaps"))) {
//             return;
//         }
//         assertEq(docTokenHandlerDex.supportsInterface(type(ITokenHandler).interfaceId), true);
//     }

//     function testDTHDModifyMinPurchaseAmount() external {
//         if (keccak256(abi.encodePacked(testEnv)) != keccak256(abi.encodePacked("dexSwaps"))) {
//             return;
//         }
//         vm.prank(OWNER);
//         docTokenHandlerDex.modifyMinPurchaseAmount(1000);
//         uint256 newPurchaseAmount = docTokenHandlerDex.getMinPurchaseAmount();
//         assertEq(newPurchaseAmount, 1000);
//     }

//     function testDTHDSetFeeRateParams() external {
//         if (keccak256(abi.encodePacked(testEnv)) != keccak256(abi.encodePacked("dexSwaps"))) {
//             return;
//         }
//         vm.prank(OWNER);
//         docTokenHandlerDex.setFeeRateParams(5, 5, 5, 5);
//         assertEq(docTokenHandlerDex.getMinFeeRate(), 5);
//         assertEq(docTokenHandlerDex.getMaxFeeRate(), 5);
//         assertEq(docTokenHandlerDex.getMinAnnualAmount(), 5);
//         assertEq(docTokenHandlerDex.getMaxAnnualAmount(), 5);
//     }

//     function testDTHDSetFeeCollectorAddress() external {
//         if (keccak256(abi.encodePacked(testEnv)) != keccak256(abi.encodePacked("dexSwaps"))) {
//             return;
//         }
//         address newFeeCollector = makeAddr("newFeeCollector");
//         vm.prank(OWNER);
//         docTokenHandlerDex.setFeeCollectorAddress(newFeeCollector);
//         assertEq(docTokenHandlerDex.getFeeCollectorAddress(), newFeeCollector);
//     }
// }
