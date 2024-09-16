//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DcaManager} from "../src/DcaManager.sol";
import {DocTokenHandler} from "../src/DocTokenHandler.sol";
import {DocTokenHandlerDex} from "../src/DocTokenHandlerDex.sol";
import {IWRBTC} from "../src//interfaces/IWRBTC.sol";
import {AdminOperations} from "../src/AdminOperations.sol";
import {ICoinPairPrice} from "./interfaces/ICoinPairPrice.sol";
import {console} from "forge-std/Test.sol";
import "../test/Constants.sol";

contract DeployContracts is Script {
    address OWNER = makeAddr(OWNER_STRING);
    address FEE_COLLECTOR = makeAddr(FEE_COLLECTOR_STRING);
    uint256 MIN_PURCHASE_AMOUNT = 10 ether; // at least 10 DOC on each purchase
    
    address[] memory swapIntermediateTokens = new address[](0); // Empty arrays for local tests. TODO: fork tests!!!!!
    uint24[] memory swapPoolFeeRates = new uint24[](0);

    function run() external returns (AdminOperations, DocTokenHandler, DcaManager, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address docToken, address mocProxy, address kDocToken, address wrBtcToken, address swapRouter02, address btcPriceOracle) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        // After startBroadcast -> "real" tx
        AdminOperations adminOperations = new AdminOperations();
        DcaManager dcaManager = new DcaManager(address(adminOperations));
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

        DocTokenHandlerDex docTokenHandlerDex = new DocTokenHandlerDex(
            address(dcaManager),
            docToken,
            kDocToken,
            wrBtcToken,
            swapRouter02,
            swapIntermediateTokens,
            swapPoolFeeRates,
            ICoinPairPrice(mocOracle),
            FEE_COLLECTOR,
            MIN_PURCHASE_AMOUNT,
            MIN_FEE_RATE,
            MAX_FEE_RATE,
            MIN_ANNUAL_AMOUNT,
            MAX_ANNUAL_AMOUNT,
            DOC_YIELDS_INTEREST
        );
        
        // For local tests:
        dcaManager.transferOwnership(OWNER); // Only for tests!!!
        adminOperations.transferOwnership(OWNER); // Only for tests!!!
        docTokenHandler.transferOwnership(OWNER); // Only for tests!!!
        docTokenHandlerDex.transferOwnership(OWNER); // Only for tests!!!

        // For back-end and front-end devs to test:
        // rbtcDca.transferOwnership(0x8191c3a9DF486A09d8087E99A1b2b6885Cc17214); // Carlos
        // rbtcDca.transferOwnership(0x03B1E454F902771A7071335f44042A3233836BB3); // Pau

        vm.stopBroadcast();
        return (adminOperations, docTokenHandler, dcaManager, helperConfig);
    }
}
