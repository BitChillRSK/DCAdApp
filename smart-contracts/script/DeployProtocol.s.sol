// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/protocol/TokenHandler.sol";
import "../src/protocol/DcaManager.sol";
import "../src/protocol/SwapExecutor.sol";

contract DeployScript is Script {
    address OWNER = makeAddr("owner");

    function run() public {

        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        (address docToken, address mocProxy, address kdocToken) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();

        TokenHandler tokenHandler = new TokenHandler(docToken, mocProxy);
        DcaManager dcaManager = new DcaManager(address(tokenHandler));
        SwapExecutor swapExecutor = new SwapExecutor(address(tokenHandler), address(dcaManager));

        vm.stopBroadcast(); // Stop broadcasting transactions
        return (tokenHandler, dcaManager, swapExecutor, helperConfig);
    }
}