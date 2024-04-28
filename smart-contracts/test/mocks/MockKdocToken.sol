// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IDocToken} from "../../src/interfaces/IDocToken.sol";

contract MockKdocToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    IDocToken immutable i_docToken;

    constructor(address initialOwner, address docTokenAddress)
        ERC20("Tropykus kDOC", "kDOC")
        Ownable(initialOwner)
        ERC20Permit("Tropykus kDOC")
    {
        i_docToken = IDocToken(docTokenAddress);
    }

    function mint(uint256 amount) public returns (uint256) {
        require(allowance(msg.sender, address(this)) >= amount);
        i_docToken.transferFrom(msg.sender, address(this), amount);
        transferFrom(address(this), msg.sender, 500 * amount); // In this mock: 1 DOC = 500 kDOC
        return 0;
    }

    function redeemUnderlying(uint256 amount) public returns (uint256) {
        require(balanceOf(msg.sender) > amount);
        i_docToken.transferFrom(address(this), msg.sender, amount);
        transferFrom(msg.sender, address(this), 500 * amount); // In this mock: 1 DOC = 500 kDOC
        return 0;
    }
}
