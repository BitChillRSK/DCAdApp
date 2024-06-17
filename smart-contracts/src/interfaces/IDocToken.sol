// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IDocToken
 * @author BitChill team: Antonio Rodríguez-Ynyesto
 * @dev Interface for the DOC token contract.
 */
interface IDocToken {
    /**
     * @dev This function checks the allowance the owner of some DOC has given to a spender
     *
     * @param owner the address that owns of the DOC
     * @param spender the address allowed to spend them
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev This function transfers an amount of DOC from a sender to a recipient
     *
     * @param sender the address whose DOC is sent
     * @param recipient the address that receives them
     * @param amount the amount of DOC transferred
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev This function transfers an amount of DOC from the msg.sender to a recipient
     *
     * @param recipient the address that receives the DOC
     * @param amount the amount of DOC transferred
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of `msg.sender`
     * @dev This function emits the Approval event, allowing for applications to react to updates in allowances.
     * `spender` cannot be the zero address.
     * @param spender The address which will be authorized to spend the tokens.
     * @param amount The amount of tokens to be approved for spending.
     * @return success A boolean value indicating whether the approval was successful.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}
