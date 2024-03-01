//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {RbtcDca} from "../src/RbtcDca.sol";
import {console} from "forge-std/Test.sol";

contract DeployRbtcDca is Script {
    address OWNER = makeAddr("owner");

    function run() external returns (RbtcDca, HelperConfig) {
        // Before startBroadcast -> not a "real" tx
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        (address docToken, address mocProxy) = helperConfig.activeNetworkConfig();

        //address walletC = vm.envAddress("WALLET_C");
        //address walletP = vm.envAddress("WALLET_P");

        vm.startBroadcast();
        // After startBroadcast -> "real" tx
        RbtcDca rbtcDca = new RbtcDca(docToken, mocProxy);
        rbtcDca.transferOwnership(OWNER); // Only for tests!!!
        // rbtcDca.transferOwnership(walletC); // Carlos
        // rbtcDca.transferOwnership(walletP); // Pau
        vm.stopBroadcast();
        return (rbtcDca, helperConfig);
    }
}
