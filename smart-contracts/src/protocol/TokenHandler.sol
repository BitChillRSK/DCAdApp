// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IDocTokenContract.sol";
import "./interfaces/IMocProxyContract.sol";

contract TokenHandler is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    IDocTokenContract private docToken;
    IMocProxyContract private mocProxy;

    event DocDeposited(address indexed user, uint256 amount);
    event DocWithdrawn(address indexed user, uint256 amount);

    function initialize(address _docTokenAddress, address _mocProxyAddress) public initializer {
        __Ownable_init();
        docToken = IDocTokenContract(_docTokenAddress);
        mocProxy = IMocProxyContract(_mocProxyAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function depositDocToken(address user, uint256 amount) external onlyOwner {
        require(docToken.allowance(user, address(this)) >= amount, "Insufficient allowance");
        require(docToken.transferFrom(user, address(this), amount), "Transfer failed");
        emit DocDeposited(user, amount);
    }

    function withdrawDocToken(address user, uint256 amount) external onlyOwner {
        require(docToken.transfer(user, amount), "Transfer failed");
        emit DocWithdrawn(user, amount);
    }

    // Additional interaction functions with the MoC Proxy
    function redeemDocForRbtc(uint256 docAmount) external onlyOwner {
        mocProxy.redeemDocRequest(docAmount);
        // Further implementation required based on MoC Proxy responses or events
    }
}