// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ITokenHandlerFactory
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the TokenHandlerFactory contract.
 */
interface ITokenHandlerFactory {
    //////////////////////
    // Events ////////////
    //////////////////////
    event TokenHandlerCreated(address indexed token, address handler);
    event TokenHandlerUpdated(address indexed token, address newHandler);

    ///////////////////////////////
    // External functions /////////
    ///////////////////////////////

    /**
     * @notice Creates a new token handler contract for a specified stablecoin and registers it.
     * @param token The address of the stablecoin for which the token handler is created.
     * @return handler The address of the newly created token handler contract.
     */
    function createTokenHandler(address token) external returns (address handler);

    /**
     * @notice Updates the token handler contract for a specified stablecoin.
     * @param token The address of the stablecoin for which the token handler is updated.
     * @param newHandler The address of the new token handler contract.
     */
    function updateTokenHandler(address token, address newHandler) external;

    /**
     * @notice Retrieves the address of the token handler contract for a specified stablecoin.
     * @param token The address of the stablecoin.
     * @return handler The address of the token handler contract.
     */
    function getTokenHandler(address token) external view returns (address handler);
}
