// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

import {Test} from "forge-std/Test.sol";
import {IdleDocHandlerMoc} from "src/idle/IdleDocHandlerMoc.sol";
import {IFeeHandler} from "src/interfaces/IFeeHandler.sol";
import {IPurchaseRbtc} from "src/interfaces/IPurchaseRbtc.sol";
import {MockStablecoin} from "../mocks/MockStablecoin.sol";
import {MockMocProxy} from "../mocks/MockMocProxy.sol";
import "../Constants.sol";

/**
 * @notice PurchaseMoc: free-DOC redeem only; MoC revert data bubbles; zero output fails closed.
 */
contract PurchaseMocBehaviorTest is Test {
    MockStablecoin internal doc;
    MockMocProxy internal moc;
    IdleDocHandlerMoc internal handler;

    address internal buyer = address(0xB1);

    function setUp() public {
        doc = new MockStablecoin(address(this));
        moc = new MockMocProxy(address(doc));
        vm.deal(address(moc), 100 ether);

        IFeeHandler.FeeSettings memory feeSettings = IFeeHandler.FeeSettings({
            minFeeRate: MIN_FEE_RATE,
            maxFeeRate: MAX_FEE_RATE_TEST,
            feePurchaseLowerBound: FEE_PURCHASE_LOWER_BOUND,
            feePurchaseUpperBound: FEE_PURCHASE_UPPER_BOUND
        });
        // dcaManager = this so onlyDcaManager purchase entry points are callable here.
        handler = new IdleDocHandlerMoc(
            address(this), address(doc), address(0xFEE), address(moc), feeSettings, address(this)
        );

        doc.mint(buyer, 100 ether);
        vm.prank(buyer);
        doc.approve(address(handler), type(uint256).max);
        handler.depositToken(buyer, 100 ether);

        // Local MoC mock pulls DOC from the handler (live MoC uses a different path).
        vm.prank(address(handler));
        doc.approve(address(moc), type(uint256).max);
    }

    function test_redeemFreeDocAlonePaysRbtc() public {
        uint256 purchaseAmount = 25 ether;
        address[] memory buyers = new address[](1);
        buyers[0] = buyer;
        uint64[] memory scheduleIds = new uint64[](1);
        scheduleIds[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = purchaseAmount;

        uint256 rbtcBefore = IPurchaseRbtc(address(handler)).getAccumulatedRbtcBalance(buyer);
        handler.batchBuyRbtc(buyers, scheduleIds, amounts, 0);
        uint256 rbtcAfter = IPurchaseRbtc(address(handler)).getAccumulatedRbtcBalance(buyer);

        assertGt(rbtcAfter, rbtcBefore);
        assertEq(moc.docRequestCalls(), 0, "settlement request must not be called");
        assertEq(moc.freeDocCalls(), 1);
    }

    function test_mocRevertBubblesOriginalReason() public {
        moc.setRevertFreeDoc("moc free redeem failed");

        address[] memory buyers = new address[](1);
        buyers[0] = buyer;
        uint64[] memory scheduleIds = new uint64[](1);
        scheduleIds[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 25 ether;

        vm.expectRevert(bytes("moc free redeem failed"));
        handler.batchBuyRbtc(buyers, scheduleIds, amounts, 0);
    }

    function test_zeroRbtcOutputFailsClosed() public {
        // MoC "succeeds" but sends no value → measured delta is 0 → batch purchase reverts.
        // Counter asserts after expectRevert are useless: the whole call rolls back.
        vm.deal(address(moc), 0);

        address[] memory buyers = new address[](1);
        buyers[0] = buyer;
        uint64[] memory scheduleIds = new uint64[](1);
        scheduleIds[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 25 ether;

        vm.expectRevert(
            abi.encodeWithSelector(IPurchaseRbtc.PurchaseRbtc__RbtcBatchPurchaseFailed.selector, address(doc))
        );
        handler.batchBuyRbtc(buyers, scheduleIds, amounts, 0);
    }
}
