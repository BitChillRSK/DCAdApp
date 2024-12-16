// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";

string constant OWNER_STRING = "owner";
string constant USER_STRING = "user";
string constant ADMIN_STRING = "ADMIN";
string constant SWAPPER_STRING = "SWAPPER";
string constant FEE_COLLECTOR_STRING = "feeCollector";
address constant OWNER_ADDR = 0x226E865Ab298e542c5e5098694eFaFfe111F93D3;
address constant SWAPPER_ADDR = 0x6F971082A05b7965c6C9bf38aEF009cd6bFBea45;
address constant ADMIN_ADDR = 0xf6336be0205D2F03976878cc1c80E60C66C86C50;
address constant FEE_COLLECTOR_ADDR = 0x28613E85D920dE907c2bBf03F1C62E6FF52C9c13;
uint256 constant MIN_PURCHASE_AMOUNT = 25 ether; // at least 25 DOC on each purchase
uint256 constant MIN_FEE_RATE = 100;
uint256 constant MAX_FEE_RATE = 100;
uint256 constant MIN_ANNUAL_AMOUNT = 1000 ether; // 1000 DOC
uint256 constant MAX_ANNUAL_AMOUNT = 100_000 ether; // 100,000 DOC
uint256 constant FEE_PERCENTAGE_DIVISOR = 10_000;
uint256 constant BTC_PRICE = 50_000; // 1 BTC = 50,000 DOC
uint256 constant EXCHANGE_RATE_DECIMALS = 1e18; // 1 BTC = 50,000 DOC
bool constant DOC_YIELDS_INTEREST = true;
