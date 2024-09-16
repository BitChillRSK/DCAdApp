// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockDocToken} from "../test/mocks/MockDocToken.sol";
import {MockKdocToken} from "../test/mocks/MockKdocToken.sol";
import {MockMocProxy} from "../test/mocks/MockMocProxy.sol";
import {MockWrbtcToken} from "../test/mocks/MockWrbtcToken.sol";
import {MockSwapRouter02} from "../test/mocks/MockSwapRouter02.sol";
import {MockBtcPriceOracle} from "../test/mocks/MockBtcPriceOracle.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address docTokenAddress;
        address mocProxyAddress;
        address kdocTokenAddress;
        address wrbtcTokenAddress;
        address swapRouter02Address;
        address btcPriceOracleAddress;
    }

    event HelperConfig__CreatedMockDocToken(address docTokenAddress);
    event HelperConfig__CreatedMockMocProxy(address mocProxyAddress);
    event HelperConfig__CreatedMockKdocToken(address kdocTokenAddress);
    event HelperConfig__CreatedWrbtcToken(address wrbtcTokenAddress);
    event HelperConfig__CreatedSwapRouter02(address swapRouter02Address);
    event HelperConfig__CreatedMockBtcPriceOracleAddress(address btcPriceOracleAddress);

    constructor() {
        if (block.chainid == 31) {
            activeNetworkConfig = getRootstockTestnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getRootstockTestnetConfig() public pure returns (NetworkConfig memory RootstockTestnetNetworkConfig) {
        RootstockTestnetNetworkConfig = NetworkConfig({
            docTokenAddress: 0xCB46c0ddc60D18eFEB0E586C17Af6ea36452Dae0, // Address of the DOC token contract in Rootstock testnet
            mocProxyAddress: 0x2820f6d4D199B8D8838A4B26F9917754B86a0c1F, // Address of the MoC proxy contract in Rootstock testnet
            kdocTokenAddress: 0x71e6B108d823C2786f8EF63A3E0589576B4F3914, // Address of the kDOC proxy contract in Rootstock testnet
            wrbtcTokenAddress: 0x69FE5cEC81D5eF92600c1A0dB1F11986AB3758Ab // Address of the WRBTC contract in Rootstock testnet
                // SwapRouter02 not deployed on RSK testnet!!! 😱😱😱
                // Btc price oracle not deployed on RSK testnet!!!
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
        MockKdocToken mockKdocToken = new MockKdocToken(msg.sender, address(mockDocToken));
        MockWrbtcToken mockWrBtcToken = new MockWrbtcToken();
        MockSwapRouter02 mockSwapRouter02 = new MockSwapRouter02();
        MockBtcPriceOracle mockBtcPriceOracle = new MockBtcPriceOracle();
        vm.stopBroadcast();
        emit HelperConfig__CreatedMockDocToken(address(mockDocToken));
        emit HelperConfig__CreatedMockMocProxy(address(mockMocProxy));
        emit HelperConfig__CreatedMockKdocToken(address(mockKdocToken));
        emit HelperConfig__CreatedWrbtcToken(address(mockWrBtcToken));
        emit HelperConfig__CreatedSwapRouter02(address(mockSwapRouter02));
        emit HelperConfig__CreatedBtcPriceOracle(address(mockBtcPriceOracle));

        anvilNetworkConfig = NetworkConfig({
            docTokenAddress: address(mockDocToken),
            mocProxyAddress: address(mockMocProxy),
            kdocTokenAddress: address(mockKdocToken),
            wrbtcTokenAddress: address(wrBtcToken),
            swapRouter02Address: address(swapRouter02)
            btcPriceOracleAddress: address(mockBtcPriceOracle)
        });
    }

    // MAINNET CONTRACTS
    // DOC: 0xe700691dA7b9851F2F35f8b8182c69c53CcaD9Db
    // rUSDT: 0xef213441A85dF4d7ACbDaE0Cf78004e1E486bB96
    // WRBTC: 0x542fDA317318eBF1d3DEAf76E0b632741A7e677d
    // Swap router 02: 0x0B14ff67f0014046b4b99057Aec4509640b3947A
}
