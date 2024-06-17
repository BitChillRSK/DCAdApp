// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IDocToken} from "../../src/interfaces/IDocToken.sol";
import {console} from "forge-std/Test.sol";

contract MockKdocToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    IDocToken immutable i_docToken;
    uint256 constant EXCHANGE_RATE = 50;
    uint256 constant DECIMALS = 1E18;

    constructor(address initialOwner, address docTokenAddress)
        ERC20("Tropykus kDOC", "kDOC")
        Ownable(initialOwner)
        ERC20Permit("Tropykus kDOC")
    {
        i_docToken = IDocToken(docTokenAddress);
    }

    function mint(uint256 amount) public returns (uint256) {
        require(i_docToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        i_docToken.transferFrom(msg.sender, address(this), amount); // Deposit DOC into Tropykus
        _mint(msg.sender, amount * EXCHANGE_RATE); //  Mint kDOC to user that deposited DOC
        return 0;
    }

    function redeemUnderlying(uint256 amount) public returns (uint256) {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        i_docToken.transfer(msg.sender, amount);
        _burn(msg.sender, EXCHANGE_RATE * amount); 
        return 0;
    }

    function exchangeRateStored() public pure returns (uint256) {
        return EXCHANGE_RATE * DECIMALS;
    }

    function getSupplierSnapshotStored(address user) external view returns (
            uint256,
            uint256,
            uint256,
            uint256) {
        console.log("getSupplierSnapshotStored: balance = ", balanceOf(user));
        uint256 underlyingAmount = balanceOf(user) / EXCHANGE_RATE;
        console.log("getSupplierSnapshotStored: underlyingAmount = ", underlyingAmount);
        return(0, underlyingAmount, 0, 0);
    }
}
