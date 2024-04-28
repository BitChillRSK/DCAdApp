// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IKdocToken
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the kDOC token contract.
 */
interface IkDocToken {
    /**
     * @dev This function is used to deposit DOC into the Tropykus protocol and get kDOC in exchange
     *
     * @param mintAmount the amount of DOC to be deposited
     */
    function mint(uint256 mintAmount) external returns (uint256);
    /**
     * @dev This function is used to withdraw DOC from the Tropykus protocol and give back the corresponding kDOC
     * @param redeemAmount the amount of DOC to be withdrawn
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}
