// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Constants.sol";

contract MockSwapRouter02 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    IERC20 s_tokenIn;
    IERC20 s_tokenOut;

    constructor(address tokenIn, address tokenOut) {
        s_tokenIn = IERC20(tokenIn);
        s_tokenOut = IERC20(tokenOut);
    }

    /*
     * @notice: here we're mocking a token-WRBTC swap
     * @notice: this function requires a previous approval and having funded the contract with WRBTC
     */
    function exactInput(ExactInputParams calldata params) external returns (uint256 amountOut) {
        s_tokenIn.transferFrom(msg.sender, address(this), params.amountIn);

        amountOut = params.amountIn / BTC_PRICE;

        s_tokenOut.transfer(msg.sender, amountOut);

        return amountOut;
    }
}
