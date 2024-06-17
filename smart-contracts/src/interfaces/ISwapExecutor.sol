// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ISwapExecutor
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the SwapExecutor contract.
 */
interface ISwapExecutor {
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function buyRbtc(address buyer) external;
}
