// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenHandler.sol";
import "./DcaManager.sol";

contract SwapExecutor is Ownable {
    TokenHandler public tokenHandler;
    DcaManager public dcaManager;

    event SwapExecuted(address indexed user, uint256 docAmount, uint256 rbtcAmount);

    constructor(address payable _tokenHandlerAddress, address _dcaManagerAddress) Ownable(msg.sender) {
        tokenHandler = TokenHandler(_tokenHandlerAddress);
        dcaManager = DcaManager(_dcaManagerAddress);
    }

    function executeSwap(address buyer) external onlyOwner {
        DcaManager.DcaDetails memory userDetails = dcaManager.getUserDcaDetails(buyer);

        if (userDetails.rbtcBalance > 0) {
            require(block.timestamp - userDetails.lastPurchaseTimestamp >= userDetails.purchasePeriod, "Cannot buy yet; purchase period has not elapsed.");
        }

        uint256 rbtcAmount = tokenHandler.redeemDocForRbtc(buyer, userDetails.docPurchaseAmount);
        dcaManager.updatePurchaseDetails(buyer, userDetails.docPurchaseAmount, rbtcAmount);
        
        emit SwapExecuted(buyer, userDetails.docPurchaseAmount, rbtcAmount);
    }
}