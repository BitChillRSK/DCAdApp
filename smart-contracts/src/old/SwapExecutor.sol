// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IDocToken} from "./interfaces/IDocToken.sol";
import {IkDocToken} from "./interfaces/IkDocToken.sol";
import {ISwapExecutor} from "./interfaces/ISwapExecutor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {DcaManager} from "./DcaManager.sol";

contract SwapExecutor is ISwapExecutor, Ownable {
    //////////////////////
    // Modifiers /////////
    //////////////////////
    modifier onlyMocProxy() {
        if (msg.sender != address(i_mocProxy)) revert RbtcDca__OnlyMocProxyCanSendRbtcToDcaContract();
        _;
    }

    //////////////////////
    // Functions /////////
    //////////////////////
    constructor(address docTokenAddress, address mocProxyAddress) Ownable(msg.sender) {
        i_docToken = IDocToken(docTokenAddress);
        i_mocProxy = IMocProxy(mocProxyAddress);
        // i_kdocToken = IkDocToken(kdocTokenAddress);
    }

    receive() external payable onlyMocProxy {}

    /**
     * @param buyer: the user on behalf of which the contract is making the rBTC purchase
     * @notice this function will be called periodically through a CRON job running on a web server
     * @notice it is checked that the purchase period has elapsed, as added security on top of onlyOwner modifier
     */
    function buyRbtc(address buyer) external onlyOwner {
        // If the user made their first purchase, check that period has elapsed before making a new purchase
        if (s_dcaDetails[buyer].rbtcBalance > 0) {
            if (block.timestamp - s_dcaDetails[buyer].lastPurchaseTimestamp < s_dcaDetails[buyer].purchasePeriod) {
                revert RbtcDca__CannotBuyIfPurchasePeriodHasNotElapsed();
            }
        }

        s_dcaDetails[buyer].docBalance -= s_dcaDetails[buyer].docPurchaseAmount;
        s_dcaDetails[buyer].lastPurchaseTimestamp = block.timestamp;

        // Redeem DOC for rBTC
        (bool success,) = address(i_mocProxy).call(
            abi.encodeWithSignature("redeemDocRequest(uint256)", s_dcaDetails[buyer].docPurchaseAmount)
        );
        if (!success) revert RbtcDca__RedeemDocRequestFailed();
        // Now that redeemDocRequest has completed, proceed to redeemFreeDoc
        uint256 balancePrev = address(this).balance;
        (success,) = address(i_mocProxy).call(
            abi.encodeWithSignature("redeemFreeDoc(uint256)", s_dcaDetails[buyer].docPurchaseAmount)
        );
        if (!success) revert RbtcDca__RedeemFreeDocFailed();
        uint256 balancePost = address(this).balance;

        s_dcaDetails[buyer].rbtcBalance += (balancePost - balancePrev);

        emit RbtcBought(buyer, s_dcaDetails[buyer].docPurchaseAmount, balancePost - balancePrev);
    }
}
