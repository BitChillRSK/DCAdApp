// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";

string constant OWNER_STRING = "owner";
string constant USER_STRING = "user";
string constant ADMIN_STRING = "ADMIN";
string constant SWAPPER_STRING = "SWAPPER";
string constant FEE_COLLECTOR_STRING = "feeCollector";
address constant OWNER_ADDR = 0x79cA18BE6Cc3C7A42A8e5C2DF2B557141C365618;
address constant SWAPPER_ADDR = 0x99256dA8dD83274aF7A079D8b0440012dC7B847e;
address constant ADMIN_ADDR = 0xAF852e82410EC7C7EaD4c38B2308B25191665F54;
address constant FEE_COLLECTOR_ADDR = 0xB14a8B60147afB21caD71cdEe38F849742A234c2;
uint256 constant MIN_PURCHASE_AMOUNT = 25 ether; // at least 25 DOC on each purchase
uint256 constant MIN_FEE_RATE = 100;
uint256 constant MAX_FEE_RATE = 100;
uint256 constant MIN_ANNUAL_AMOUNT = 1000 ether; // 1000 DOC
uint256 constant MAX_ANNUAL_AMOUNT = 100_000 ether; // 100,000 DOC
uint256 constant FEE_PERCENTAGE_DIVISOR = 10_000;
uint256 constant BTC_PRICE = 50_000; // 1 BTC = 50,000 DOC
uint256 constant EXCHANGE_RATE_DECIMALS = 1e18; // 1 BTC = 50,000 DOC
bool constant DOC_YIELDS_INTEREST = true;
