// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Constants.sol";

contract MockBtcPriceOracle {
    function getPrice() external view returns (uint256) {
        return BTC_PRICE;
    }
}
