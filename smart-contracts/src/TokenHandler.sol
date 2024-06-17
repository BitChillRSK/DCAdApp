// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ITokenHandler} from "./interfaces/ITokenHandler.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console} from "forge-std/Test.sol";

/**
 * @title TokenHandler
 * @dev Base contract for handling various tokens.
 */
abstract contract TokenHandler is ITokenHandler, Ownable /*, IERC165*/ {
    //////////////////////
    // State variables ///
    //////////////////////
    address public immutable i_stableToken; // The stablecoin token to be deposited
    uint256 internal s_minPurchaseAmount; // The minimum amount of this token for periodic purchases
    address public immutable i_dcaManager; // The DCA manager contract
    mapping(address user => uint256 amount) internal s_usersAccumulatedRbtc;
    uint256 constant FEE_PERCENTAGE_DIVISOR = 10_000; // feeRate will belong to [100, 200], so we need to divide by 10,000 (100 * 100)
    uint256 internal s_minFeeRate; // Minimum fee rate 
    uint256 internal s_maxFeeRate; // Maximum fee rate
    uint256 internal s_minAnnualAmount; // Spending below min annual amount annually gets the maximum fee rate
    uint256 internal s_maxAnnualAmount; // Spending above max annually gets the minimum fee rate
    address internal s_feeCollector; // Address to which the fees charged to the user will be sent
    bool internal immutable i_yieldsInterest; // Whether the token deposited will yield interest while waiting to be spent on DCA purchases

    // Store user DCA details generically
    // mapping(address => DcaDetails) public dcaDetails;

    //////////////////////
    // Modifiers /////////
    //////////////////////
    modifier onlyDcaManager() {
        if (msg.sender != i_dcaManager) revert TokenHandler__OnlyDcaManagerCanCall();
        _;
    }

    constructor(address dcaManagerAddress, address tokenAddress, uint256 minPurchaseAmount, address feeCollector, 
                uint256 minFeeRate, uint256 maxFeeRate, uint256 minAnnualAmount, uint256 maxAnnualAmount, bool yieldsInterest) {
        i_dcaManager = dcaManagerAddress;
        i_stableToken = tokenAddress;
        s_minPurchaseAmount = minPurchaseAmount;
        s_feeCollector = feeCollector;
        s_minFeeRate = minFeeRate;
        s_feeCollector = feeCollector;
        s_maxFeeRate = maxFeeRate;
        s_minAnnualAmount = minAnnualAmount;
        s_maxAnnualAmount = maxAnnualAmount;
        i_yieldsInterest = yieldsInterest;
    }


    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable /*onlyMocProxy*/ {} // Cambiar onlyMocProxy por algo que controle que el rbtc venga de fuentes conocidas?

    /**
     * @notice deposit the full token amount for DCA on the contract
     * @param user: the address of the user making the deposit
     * @param depositAmount: the amount to deposit
     */
    function depositToken(address user, uint256 depositAmount) public override virtual onlyDcaManager {

        // Transfer the selected token from the user to this contract. The user must have called the token contract's
        // approve function with this contract's address and the amount approved
        if (IERC20(i_stableToken).allowance(user, address(this)) < depositAmount) {
            revert TokenHandler__InsufficientTokenAllowance(i_stableToken);
        }

        bool depositSuccess = IERC20(i_stableToken).transferFrom(user, address(this), depositAmount);
        if (!depositSuccess) revert TokenHandler__TokenDepositFailed(i_stableToken);

        emit TokenHandler__TokenDeposited(i_stableToken, user, depositAmount);
    }

    /**
     * @notice withdraw some or all of the DOC previously deposited
     * @param withdrawalAmount: the amount of DOC to withdraw
     */
    function withdrawToken(address user, uint256 withdrawalAmount) public override virtual onlyDcaManager {

        // Transfer DOC from this contract back to the user
        bool withdrawalSuccess = IERC20(i_stableToken).transfer(user, withdrawalAmount);
        if (!withdrawalSuccess) revert TokenHandler__TokenWithdrawalFailed(i_stableToken);

        emit TokenHandler__TokenWithdrawn(i_stableToken, user, withdrawalAmount);
    }

    /**
     * @notice the user can at any time withdraw the rBTC that has been accumulated through periodical purchases
     */
    function withdrawAccumulatedRbtc(address user) external override {
        uint256 rbtcBalance = s_usersAccumulatedRbtc[user];
        if (rbtcBalance == 0) revert TokenHandler__NoAccumulatedRbtcToWithdraw();

        s_usersAccumulatedRbtc[user] = 0;
        // Transfer RBTC from this contract back to the user
        (bool sent,) = user.call{value: rbtcBalance}("");
        if (!sent) revert TokenHandler__rBtcWithdrawalFailed();
        emit TokenHandler__rBtcWithdrawn(user, rbtcBalance);
    }

    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == type(ITokenHandler).interfaceId;
    }

    function modifyMinPurchaseAmount(uint256 minPurchaseAmount) external override onlyOwner {
        s_minPurchaseAmount = minPurchaseAmount;
    }

    function setFeeRateParams(uint256 minFeeRate, uint256 maxFeeRate, uint256 minAnnualAmount, uint256 maxAnnualAmount) external override onlyOwner {
        if(s_minFeeRate != minFeeRate) setMinFeeRate(minFeeRate);
        if(s_maxFeeRate != maxFeeRate) setMaxFeeRate(maxFeeRate); 
        if(s_minAnnualAmount != minAnnualAmount) setMinAnnualAmount(minAnnualAmount); 
        if(s_maxAnnualAmount != maxAnnualAmount) setMaxAnnualAmount(maxAnnualAmount); 
    }

    function setMinFeeRate(uint256 minFeeRate) public override onlyOwner {
        s_minFeeRate = minFeeRate; 
    }

    function setMaxFeeRate(uint256 maxFeeRate) public override onlyOwner {
        s_maxFeeRate = maxFeeRate; 
    }

    function setMinAnnualAmount(uint256 minAnnualAmount) public override onlyOwner {
        s_minAnnualAmount = minAnnualAmount; 
    }

    function setMaxAnnualAmount(uint256 maxAnnualAmount) public override onlyOwner {
        s_maxAnnualAmount = maxAnnualAmount; 
    }

    function setFeeCollectorAddress(address feeCollector) external override onlyOwner {
        s_feeCollector = feeCollector; 
    }


    
    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getMinPurchaseAmount() external view returns (uint256) {
        return s_minPurchaseAmount;
    }
    
    function getAccumulatedRbtcBalance() external view override returns (uint256) {
        return s_usersAccumulatedRbtc[msg.sender];
    }
    
    function depositsYieldInterest() external view override returns (bool){
        return i_yieldsInterest;
    }

    function getMinFeeRate() public view returns(uint256) {
        return s_minFeeRate; 
    }

    function getMaxFeeRate() public view returns(uint256) {
        return s_maxFeeRate; 
    }

    function getMinAnnualAmount() public view returns(uint256) {
        return s_minAnnualAmount; 
    }

    function getMaxAnnualAmount() public view returns(uint256) {
        return s_maxAnnualAmount; 
    }

    function getFeeCollectorAddress() external view returns(address) {
        return s_feeCollector; 
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculates the fee rate based on the annual spending.
     * @param purchaseAmount The amount of stablecoin to be swapped for rBTC in each purchase.
     * @param purchasePeriod The period between purchases in seconds.
     * @return The fee rate in basis points.
     */
    function _calculateFee(uint256 purchaseAmount, uint256 purchasePeriod) internal view returns (uint256) {
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

    // function transferFee(address feeCollector, uint256 fee) external onlyDcaManager {
    function _transferFee(uint256 fee) internal {
        bool feeTransferSuccess = IERC20(i_stableToken).transfer(s_feeCollector, fee);
        if (!feeTransferSuccess) revert TokenHandler__FeeTransferFailed(s_feeCollector, i_stableToken, fee);
    }
}
