// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDocTokenContract {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}