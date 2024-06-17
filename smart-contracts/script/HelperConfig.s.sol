// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockDocToken} from "../test/mocks/MockDocToken.sol";
import {MockKdocToken} from "../test/mocks/MockKdocToken.sol";
import {MockMocProxy} from "../test/mocks/MockMocProxy.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address docTokenAddress;
        address mocProxyAddress;
        address kdocTokenAddress;
    }

    event HelperConfig__CreatedMockDocToken(address docTokenAddress);
    event HelperConfig__CreatedMockMocProxy(address mocProxyAddress);
    event HelperConfig__CreatedMockKdocToken(address kdocTokenAddress);

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
            kdocTokenAddress: 0x71e6B108d823C2786f8EF63A3E0589576B4F3914 // Address of the kDOC proxy contract in Rootstock testnet
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
}
