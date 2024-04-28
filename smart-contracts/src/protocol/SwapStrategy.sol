// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./DcaManager.sol";

contract SwapStrategy is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    DcaManager public dcaManager;

    function initialize(address _dcaManager) public initializer {
        __Ownable_init();
        dcaManager = DcaManager(_dcaManager);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function shouldExecuteSwap(address user) public view returns (bool) {
        DcaManager.DcaDetails memory details = dcaManager.getUserDcaDetails(user);
        return (block.timestamp - details.lastPurchaseTimestamp >= details.purchasePeriod);
    }

    function getDocAmountToSwap(address user) public view returns (uint256) {
        DcaManager.DcaDetails memory details = dcaManager.getUserDcaDetails(user);
        return details.docPurchaseAmount;
    }
}