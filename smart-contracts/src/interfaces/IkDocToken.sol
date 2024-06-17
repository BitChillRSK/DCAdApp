// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

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
    
    /**
     * @dev This function is used to withdraw DOC from the Tropykus protocol and give back the corresponding kDOC
     * @param owner the user that owns the DOC deposited into Tropykus
     */
    function getSupplierSnapshotStored(address owner) external returns (
            uint256 tokens,
            uint256 underlyingAmount,
            uint256 suppliedAt,
            uint256 promisedSupplyRate
        );

    /**
    * @dev Returns the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return The balance of the specified address.
    */
    function balanceOf(address owner) external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

}
