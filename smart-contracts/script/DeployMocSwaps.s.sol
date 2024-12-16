//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MocHelperConfig} from "./MocHelperConfig.s.sol";
import {DcaManager} from "../src/DcaManager.sol";
import {DocTokenHandler} from "../src/DocTokenHandler.sol";
import {AdminOperations} from "../src/AdminOperations.sol";
import {console} from "forge-std/Test.sol";
import "../test/Constants.sol";

contract DeployMocSwaps is Script {
    address FEE_COLLECTOR = FEE_COLLECTOR_ADDR;
    address OWNER = OWNER_ADDR;
    address ADMIN = ADMIN_ADDR;
    address SWAPPER = SWAPPER_ADDR;

    // function run() external returns (AdminOperations, DocTokenHandler, DcaManager, MocHelperConfig) {
    function run() external returns (DocTokenHandler, DcaManager, MocHelperConfig) {
        MocHelperConfig helperConfig = new MocHelperConfig();
        (address docToken, address mocProxy, address kDocToken) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        // After startBroadcast -> "real" tx
        // AdminOperations adminOperations = new AdminOperations();
        // DcaManager dcaManager = new DcaManager(address(adminOperations));
        DcaManager dcaManager = new DcaManager(address(0x07623b4bfA188687B683CbF242C12A7d4bD7D355));
        DocTokenHandler docTokenHandler = new DocTokenHandler(
            address(dcaManager),
            docToken,
            kDocToken,
            MIN_PURCHASE_AMOUNT,
            FEE_COLLECTOR,
            mocProxy,
            MIN_FEE_RATE,
            MAX_FEE_RATE,
            MIN_ANNUAL_AMOUNT,
            MAX_ANNUAL_AMOUNT,
            DOC_YIELDS_INTEREST
        );

        // For local tests:
        if (block.chainid == 31337) {
            // adminOperations.setAdminRole(ADMIN); // Only for tests!!!
            // adminOperations.setSwapperRole(SWAPPER); // Only for tests!!!
            // adminOperations.transferOwnership(OWNER); // Only for tests!!!
            dcaManager.transferOwnership(OWNER); // Only for tests!!!
            docTokenHandler.transferOwnership(OWNER); // Only for tests!!!
        }

        if (block.chainid == 31 || block.chainid == 30) {
            // adminOperations.setAdminRole(ADMIN);
        }
        // For back-end and front-end devs to test:
        // rbtcDca.transferOwnership(0x8191c3a9DF486A09d8087E99A1b2b6885Cc17214); // Carlos
        // rbtcDca.transferOwnership(0x03B1E454F902771A7071335f44042A3233836BB3); // Pau

        vm.stopBroadcast();
        // return (adminOperations, docTokenHandler, dcaManager, helperConfig);
        return (docTokenHandler, dcaManager, helperConfig);
    }
}
