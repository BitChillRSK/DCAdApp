// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockDocToken} from "../mocks/MockDocToken.sol";
import {Test, console} from "forge-std/Test.sol";
import "../Constants.sol";


contract MockMocProxy {
    MockDocToken mockDocToken;
    
    event MockMocProxy__DocRedeemed(address indexed user, uint256 docAmount, uint256 btcAmount);
    constructor(address docTokenAddress) {
        mockDocToken = MockDocToken(docTokenAddress);
    }    

    function redeemDocRequest(uint256 docAmount) external {        
        // mockDocToken.approve(address(this), docAmount);
    }

    function redeemFreeDoc(uint256 docAmount) external {
        uint256 redeemedRbtc = docAmount / BTC_PRICE;
        mockDocToken.transferFrom(msg.sender, address(this), docAmount);
        mockDocToken.burn(docAmount);
        (bool success,) = msg.sender.call{value: redeemedRbtc}("");
        if (success) {
            emit MockMocProxy__DocRedeemed(msg.sender, docAmount, redeemedRbtc);
        }
    }    
}
