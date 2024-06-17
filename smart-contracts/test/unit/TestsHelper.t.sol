//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import "../Constants.sol";

contract DummyERC165Contract {
    constructor (){}
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == type(IDcaManager).interfaceId; // Check against an interface different from TokenHandler's
    }
}

contract FeeCalculator {
    
    uint256 internal s_minFeeRate = MIN_FEE_RATE;
    uint256 internal s_maxFeeRate = MAX_FEE_RATE;
    uint256 internal s_minAnnualAmount = MIN_ANNUAL_AMOUNT;
    uint256 internal s_maxAnnualAmount = MAX_ANNUAL_AMOUNT;
    constructor (){}
    function calculateFee(uint256 purchaseAmount, uint256 purchasePeriod) external view returns (uint256) {
        uint256 annualSpending = (purchaseAmount * 365 days) / purchasePeriod;
        uint256 feeRate;

        if (annualSpending >= s_maxAnnualAmount) {
            feeRate = s_minFeeRate;
        } else if (annualSpending <= s_minAnnualAmount) {
            feeRate = s_maxFeeRate;
        } else {
            // Calculate the linear fee rate
            feeRate = s_maxFeeRate - ((annualSpending - s_minAnnualAmount) * (s_maxFeeRate - s_minFeeRate)) / (s_maxAnnualAmount - s_minAnnualAmount);
        }
        return purchaseAmount * feeRate / FEE_PERCENTAGE_DIVISOR;
    }
}