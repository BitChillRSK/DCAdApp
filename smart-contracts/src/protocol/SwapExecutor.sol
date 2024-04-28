// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./TokenHandler.sol";
import "./SwapStrategy.sol";

contract SwapExecutor is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    SwapStrategy public swapStrategy;
    TokenHandler public tokenHandler;

    event SwapExecuted(address indexed user, uint256 docAmount, uint256 rbtcAmount);

    function initialize(address _swapStrategy, address _tokenHandler) public initializer {
        __Ownable_init();
        swapStrategy = SwapStrategy(_swapStrategy);
        tokenHandler = TokenHandler(_tokenHandler);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function executeSwap(address user) external onlyOwner {
        require(swapStrategy.shouldExecuteSwap(user), "Swap conditions not met");

        uint256 docAmount = swapStrategy.getDocAmountToSwap(user);
        tokenHandler.redeemDocForRbtc(docAmount);  // This assumes TokenHandler has a function to handle redemption
        emit SwapExecuted(user, docAmount, 0); // Assuming 0 for rbtcAmount as placeholder
    }
}