// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IAdminOperation
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the AdminOperations contract.
 */
interface IAdminOperations {
    //////////////////////
    // Events ////////////
    //////////////////////
    event AdminOperations__TokenHandlerUpdated(address indexed token, address newHandler);

    //////////////////////
    // Errors ////////////
    //////////////////////
    error AdminOperations__EoaCannotBeHandler(address newHandler);
    error AdminOperations__ContractIsNotTokenHandler(address newHandler);

    ///////////////////////////////
    // External functions /////////
    ///////////////////////////////

    /**
     * @notice Registers token handler for a given stablecoin token address
     * @param token The address of the stablecoin for which the token handler is created.
     */
    function assignOrUpdateTokenHandler(address token, address handler) external;

    /**
     * @notice Retrieves the address of the token handler contract for a specified stablecoin.
     * @param token The address of the stablecoin.
     * @return handler The address of the token handler contract.
     */
    function getTokenHandler(address token) external view returns (address handler);
}
