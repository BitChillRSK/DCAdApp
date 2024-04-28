// //SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {Script} from "forge-std/Script.sol";
// import {HelperConfig} from "./HelperConfig.s.sol";
// import {RbtcDca} from "../src/RbtcDca.sol";
// import {console} from "forge-std/Test.sol";

// contract DeployRbtcDca is Script {
//     address OWNER = makeAddr("owner");

//     function run() external returns (RbtcDca, HelperConfig) {
//         // Before startBroadcast -> not a "real" tx
//         HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
//         (address docToken, address mocProxy) = helperConfig.activeNetworkConfig();

//         vm.startBroadcast();
//         // After startBroadcast -> "real" tx
//         RbtcDca rbtcDca = new RbtcDca(docToken, mocProxy);

//         // For local tests:
//         rbtcDca.transferOwnership(OWNER); // Only for tests!!!

//         // For back-end and front-end devs to test:
//         // rbtcDca.transferOwnership(0x8191c3a9DF486A09d8087E99A1b2b6885Cc17214); // Carlos
//         // rbtcDca.transferOwnership(0x03B1E454F902771A7071335f44042A3233836BB3); // Pau

//         vm.stopBroadcast();
//         return (rbtcDca, helperConfig);
//     }
// }
