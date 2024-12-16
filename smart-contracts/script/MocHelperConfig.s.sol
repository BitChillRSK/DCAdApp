// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MockDocToken} from "../test/mocks/MockDocToken.sol";
import {MockKdocToken} from "../test/mocks/MockKdocToken.sol";
import {MockMocProxy} from "../test/mocks/MockMocProxy.sol";
import {MockWrbtcToken} from "../test/mocks/MockWrbtcToken.sol";
import {MockSwapRouter02} from "../test/mocks/MockSwapRouter02.sol";
import {MockMocOracle} from "../test/mocks/MockMocOracle.sol";
import "../test/Constants.sol";
import {Script} from "forge-std/Script.sol";

contract MocHelperConfig is Script {
    struct NetworkConfig {
        address docTokenAddress;
        address mocProxyAddress;
        address kdocTokenAddress;
    }

    NetworkConfig public activeNetworkConfig;

    event HelperConfig__CreatedMockDocToken(address docTokenAddress);
    event HelperConfig__CreatedMockMocProxy(address mocProxyAddress);
    event HelperConfig__CreatedMockKdocToken(address kdocTokenAddress);

    constructor() {
        if (block.chainid == 31) {
            activeNetworkConfig = getRootstockTestnetConfig();
        } else if (block.chainid == 30) {
            activeNetworkConfig = getRootstockMainnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    // 0x69FE5cEC81D5eF92600c1A0dB1F11986AB3758Ab WRBTC - RSK TESTNET
    // 0x4D5a316D23eBE168d8f887b4447bf8DbFA4901CC rUSDT - RSK TESTNET
    function getRootstockTestnetConfig() public pure returns (NetworkConfig memory RootstockTestnetNetworkConfig) {
        address[] memory intermediateTokens = new address[](1);
        intermediateTokens[0] = 0x4d5A316d23EBe168D8f887b4447BF8DBfA4901cc; // Address of the rUSDT token in Rootstock testnet

        uint24[] memory poolFeeRates = new uint24[](2);
        poolFeeRates[0] = 500;
        poolFeeRates[1] = 500;

        RootstockTestnetNetworkConfig = NetworkConfig({
            docTokenAddress: 0xCB46c0ddc60D18eFEB0E586C17Af6ea36452Dae0, // Address of the DOC token contract in Rootstock testnet
            mocProxyAddress: 0x2820f6d4D199B8D8838A4B26F9917754B86a0c1F, // Address of the MoC proxy contract in Rootstock testnet
            kdocTokenAddress: 0x71e6B108d823C2786f8EF63A3E0589576B4F3914 // Address of the kDOC proxy contract in Rootstock testnet
        });
    }

    function getRootstockMainnetConfig() public pure returns (NetworkConfig memory RootstockMainnetNetworkConfig) {
        RootstockMainnetNetworkConfig = NetworkConfig({
            docTokenAddress: 0xe700691dA7b9851F2F35f8b8182c69c53CcaD9Db, // DOC
            mocProxyAddress: 0xf773B590aF754D597770937Fa8ea7AbDf2668370, // MOC
            kdocTokenAddress: 0x544Eb90e766B405134b3B3F62b6b4C23Fcd5fDa2  // kDOC
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we already have an active network config
        if (activeNetworkConfig.docTokenAddress != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockDocToken mockDocToken = new MockDocToken(msg.sender);
        MockMocProxy mockMocProxy = new MockMocProxy(address(mockDocToken));
        MockKdocToken mockKdocToken = new MockKdocToken(address(mockDocToken));
        vm.stopBroadcast();

        emit HelperConfig__CreatedMockDocToken(address(mockDocToken));
        emit HelperConfig__CreatedMockMocProxy(address(mockMocProxy));
        emit HelperConfig__CreatedMockKdocToken(address(mockKdocToken));

        anvilNetworkConfig = NetworkConfig({
            docTokenAddress: address(mockDocToken),
            mocProxyAddress: address(mockMocProxy),
            kdocTokenAddress: address(mockKdocToken)
        });
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    // MAINNET CONTRACTS
    // DOC: 0xe700691dA7b9851F2F35f8b8182c69c53CcaD9Db
    // rUSDT: 0xef213441A85dF4d7ACbDaE0Cf78004e1E486bB96
    // WRBTC: 0x542fDA317318eBF1d3DEAf76E0b632741A7e677d
}
