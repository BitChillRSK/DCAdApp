// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMocProxyContract {
    function redeemDocRequest(uint256 docAmount) external;
    function redeemFreeDoc(uint256 docAmount) external;
}