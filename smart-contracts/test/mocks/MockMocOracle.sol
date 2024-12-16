// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../test/Constants.sol";

// Mock Oracle Contract
contract MockMocOracle {
    uint256 private s_price;

    constructor() {
        s_price = BTC_PRICE;
    }

    // Mock function to simulate i_MocOracle.getPrice()
    function getPrice() external view returns (uint256) {
        return s_price;
    }

    // Function to update the price for testing purposes
    function setPrice(uint256 _newPrice) external {
        s_price = _newPrice;
    }
}
