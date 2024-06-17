//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcaManager} from "../../src/DcaManager.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {DocTokenHandler} from "../../src/DocTokenHandler.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
import {AdminOperations} from "../../src/AdminOperations.sol";
import {IAdminOperations} from "../../src/interfaces/IAdminOperations.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployContracts} from "../../script/DeployContracts.s.sol";
import {MockDocToken} from "../mocks/MockDocToken.sol";
import {MockKdocToken} from "../mocks/MockKdocToken.sol";
import {MockMocProxy} from "../mocks/MockMocProxy.sol";
import "../Constants.sol";
import "./TestsHelper.t.sol";


contract DcaDappTest is Test {
    DcaManager dcaManager;
    DocTokenHandler docTokenHandler;
    AdminOperations adminOperations;
    HelperConfig helperConfig;
    MockDocToken mockDocToken;
    MockKdocToken mockKdocToken;
    MockMocProxy mockMocProxy;
    FeeCalculator feeCalculator;

    address USER = makeAddr(USER_STRING);
    address OWNER = makeAddr(OWNER_STRING);
    address FEE_COLLECTOR = makeAddr(FEE_COLLECTOR_STRING);
    uint256 constant STARTING_RBTC_USER_BALANCE = 10 ether; // 10 rBTC
    uint256 constant USER_TOTAL_DOC = 10_000 ether; // 10000 DOC owned by the user in total
    uint256 constant DOC_TO_DEPOSIT = 1000 ether; // 1000 DOC
    uint256 constant DOC_TO_SPEND = 100 ether; // 100 DOC for periodical purchases
    uint256 constant MIN_PURCHASE_AMOUNT = 10 ether; // at least 10 DOC on each purchase
    uint256 constant MIN_PURCHASE_PERIOD = 1 days; // at most one purchase every day
    uint256 constant SCHEDULE_INDEX = 0;
    uint256 constant NUM_OF_SCHEDULES = 5;

    //////////////////////
    // Events ////////////
    //////////////////////

    // DcaManager
    // event DcaManager__TokenDeposited(address indexed user, address indexed token, uint256 amount);
    event DcaManager__TokenBalanceUpdated(address indexed token, uint256 indexed scheduleIndex, uint256 indexed amount);
    event DcaManager__DcaScheduleCreated(
        address indexed user,
        address indexed token,
        uint256 indexed scheduleIndex,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    );
    event DcaManager__DcaScheduleUpdated(
        address indexed user,
        address indexed token,
        uint256 indexed scheduleIndex,
        uint256 depositAmount,
        uint256 purchaseAmount,
        uint256 purchasePeriod
    );

    // TokenHandler
    event TokenHandler__TokenDeposited(address indexed token, address indexed user, uint256 indexed amount);
    event TokenHandler__TokenWithdrawn(address indexed token, address indexed user, uint256 indexed amount);
    event TokenHandler__RbtcBought(address indexed user, address indexed tokenSpent, uint256 indexed rBtcBought, uint256 amountSpent);
    event TokenHandler__SuccessfulRbtcBatchPurchase(address indexed token, uint256 indexed totalPurchasedRbtc, uint256 indexed totalDocAmountSpent);

    // AdminOperations
    event AdminOperations__TokenHandlerUpdated(address indexed token, address newHandler);

    //MockMocProxy
    event MockMocProxy__DocRedeemed(address indexed user, uint256 docAmount, uint256 btcAmount);

    //////////////////////
    // Errors ////////////
    //////////////////////
    // Ownable    
    error OwnableUnauthorizedAccount(address account);


    /*//////////////////////////////////////////////////////////////
                            UNIT TESTS SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public virtual {
        DeployContracts deployContracts = new DeployContracts();
        (adminOperations, docTokenHandler, dcaManager, helperConfig) = deployContracts.run();
        // console.log("Test contract", address(this));

        (address docTokenAddress, address mocProxyAddress, address kDocTokenAddress) = helperConfig.activeNetworkConfig();

        mockDocToken = MockDocToken(docTokenAddress);
        mockMocProxy = MockMocProxy(mocProxyAddress);
        mockKdocToken = MockKdocToken(kDocTokenAddress);

        // FeeCalculator helper test contract
        feeCalculator = new FeeCalculator();

        // Add tokenHandler
        vm.expectEmit(true, true, false, false);
        emit AdminOperations__TokenHandlerUpdated(docTokenAddress, address(docTokenHandler));
        vm.prank(OWNER);
        adminOperations.assignOrUpdateTokenHandler(docTokenAddress, address(docTokenHandler));

        // Deal rBTC funds to mock contract and user
        vm.deal(mocProxyAddress, 1000 ether);
        vm.deal(USER, STARTING_RBTC_USER_BALANCE);

        // Give the MoC proxy contract allowance
        mockDocToken.approve(mocProxyAddress, DOC_TO_DEPOSIT);
        
        // Give the MoC proxy contract allowance to move DOC from docTokenHandler (this is mocking behaviour) TODO: look at this carefully when deploying on testnet (pretty sure it's fine)
        vm.prank(address(docTokenHandler));
        mockDocToken.approve(mocProxyAddress, type(uint256).max);

        // Mint 10000 DOC for the user
        mockDocToken.mint(USER, USER_TOTAL_DOC);

        // Make the starting point of the tests is that the user has already deposited 1000 DOC (so withdrawals can also be tested without much hassle)
        vm.startPrank(USER);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
        dcaManager.createDcaSchedule(
            address(mockDocToken), DOC_TO_DEPOSIT, DOC_TO_SPEND, MIN_PURCHASE_PERIOD
        );
        vm.stopPrank();
    }


    /*//////////////////////////////////////////////////////////////
                      UNIT TESTS COMMON FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function depositDoc() internal {
        vm.startPrank(USER);
        uint256 userBalanceBeforeDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
        vm.expectEmit(true, true, true, false);
        emit TokenHandler__TokenDeposited(address(mockDocToken), USER, DOC_TO_DEPOSIT);
        vm.expectEmit(true, true, true, false);
        emit DcaManager__TokenBalanceUpdated(address(mockDocToken), SCHEDULE_INDEX, 2 * DOC_TO_DEPOSIT); // 2 *, since a previous deposit is made in the setup
        dcaManager.depositToken(address(mockDocToken), SCHEDULE_INDEX, DOC_TO_DEPOSIT);
        uint256 userBalanceAfterDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        assertEq(DOC_TO_DEPOSIT, userBalanceAfterDeposit - userBalanceBeforeDeposit);
        vm.stopPrank();
    }

    function withdrawDoc() internal {
        vm.startPrank(USER);
        vm.expectEmit(true, true, true, false);
        emit TokenHandler__TokenWithdrawn(address(mockDocToken), USER, DOC_TO_DEPOSIT);
        dcaManager.withdrawToken(address(mockDocToken), SCHEDULE_INDEX, DOC_TO_DEPOSIT);
        uint256 remainingAmount = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        assertEq(remainingAmount, 0);
        vm.stopPrank();
    }

    function createSeveralDcaSchedules() internal { 
        vm.startPrank(USER);
        mockDocToken.approve(address(docTokenHandler), DOC_TO_DEPOSIT);
        uint256 docToDeposit = DOC_TO_DEPOSIT / NUM_OF_SCHEDULES;
        uint256 purchaseAmount = DOC_TO_SPEND / NUM_OF_SCHEDULES;
        // Delete the schedule created in setUp to have all five schedules with the same amounts
        dcaManager.deleteDcaSchedule(address(mockDocToken), 0);
        for (uint256 i = 0; i < NUM_OF_SCHEDULES; ++i) { 
            uint256 scheduleIndex = SCHEDULE_INDEX + i;
            uint256 purchasePeriod = MIN_PURCHASE_PERIOD + i * 5 days;
            uint256 userBalanceBeforeDeposit;
            if (dcaManager.getMyDcaSchedules(address(mockDocToken)).length > scheduleIndex) {
                userBalanceBeforeDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
            } else {
                userBalanceBeforeDeposit = 0;
            }
            vm.expectEmit(true, true, true, true);
            emit DcaManager__DcaScheduleCreated(
                USER, address(mockDocToken), scheduleIndex, docToDeposit, purchaseAmount, purchasePeriod
            );
            dcaManager.createDcaSchedule(
                address(mockDocToken), docToDeposit, purchaseAmount, purchasePeriod
            );
            uint256 userBalanceAfterDeposit = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
            assertEq(docToDeposit, userBalanceAfterDeposit - userBalanceBeforeDeposit);
            assertEq(purchaseAmount, dcaManager.getSchedulePurchaseAmount(address(mockDocToken), scheduleIndex));
            assertEq(purchasePeriod, dcaManager.getSchedulePurchasePeriod(address(mockDocToken), scheduleIndex));
        }
        vm.stopPrank();
    }

    function makeSinglePurchase() internal {
        vm.startPrank(USER);
        uint256 docBalanceBeforePurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
        vm.stopPrank();
                      
        uint256 fee = feeCalculator.calculateFee(DOC_TO_SPEND, MIN_PURCHASE_PERIOD);
        uint256 netPurchaseAmount = DOC_TO_SPEND - fee;

        vm.expectEmit(true, true, true, false);
        emit TokenHandler__RbtcBought(USER, address(mockDocToken), netPurchaseAmount / BTC_PRICE, netPurchaseAmount);
        vm.prank(OWNER);
        dcaManager.buyRbtc(USER, address(mockDocToken), SCHEDULE_INDEX);

        vm.startPrank(USER);
        uint256 docBalanceAfterPurchase = dcaManager.getScheduleTokenBalance(address(mockDocToken), SCHEDULE_INDEX);
        uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
        vm.stopPrank();
        // Check that DOC was substracted and rBTC was added to user's balances
        assertEq(docBalanceBeforePurchase - docBalanceAfterPurchase, DOC_TO_SPEND);
        assertEq(RbtcBalanceAfterPurchase - RbtcBalanceBeforePurchase, netPurchaseAmount / BTC_PRICE);
    }

    function makeSeveralPurchasesWithSeveralSchedules() internal returns (uint256 totalDocSpent) {  
        // createSeveralDcaSchedules();

        uint8 numOfPurchases = 5;
        uint256 totalDocRedeemed;

        for (uint8 i; i < NUM_OF_SCHEDULES; ++i) { 
            uint256 scheduleIndex = i;
            vm.startPrank(USER);
            uint256 schedulePurchaseAmount = dcaManager.getSchedulePurchaseAmount(address(mockDocToken), scheduleIndex);
            uint256 schedulePurchasePeriod = dcaManager.getSchedulePurchasePeriod(address(mockDocToken), scheduleIndex);
            vm.stopPrank();
            uint256 fee = feeCalculator.calculateFee(schedulePurchaseAmount, schedulePurchasePeriod);
            uint256 netPurchaseAmount = schedulePurchaseAmount - fee;

            for (uint8 j; j < numOfPurchases; ++j) {
                vm.startPrank(USER);
                uint256 docBalanceBeforePurchase =
                    dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
                uint256 RbtcBalanceBeforePurchase = docTokenHandler.getAccumulatedRbtcBalance();
                vm.stopPrank();
                vm.prank(OWNER);
                dcaManager.buyRbtc(USER, address(mockDocToken), scheduleIndex);
                vm.startPrank(USER);
                uint256 docBalanceAfterPurchase =
                    dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
                uint256 RbtcBalanceAfterPurchase = docTokenHandler.getAccumulatedRbtcBalance();
                vm.stopPrank();
                // Check that DOC was substracted and rBTC was added to user's balances
                assertEq(docBalanceBeforePurchase - docBalanceAfterPurchase, schedulePurchaseAmount);
                assertEq(RbtcBalanceAfterPurchase - RbtcBalanceBeforePurchase, netPurchaseAmount / BTC_PRICE);

                totalDocSpent += netPurchaseAmount;
                totalDocRedeemed += schedulePurchaseAmount;
                console.log("DOC redeemed", schedulePurchaseAmount);

                vm.warp(block.timestamp + schedulePurchasePeriod);
            }
        }
        console.log("Total DOC spent :", totalDocSpent);
        console.log("Total DOC redeemed :", totalDocRedeemed);
        vm.prank(USER);
        assertEq(docTokenHandler.getAccumulatedRbtcBalance(), totalDocSpent / BTC_PRICE);
    }

    function makeBatchPurchasesOneUser() internal {
        uint256 prevDocTokenHandlerBalance = address(docTokenHandler).balance;
        vm.prank(USER);
        uint256 userAccumulatedRbtcPrev = docTokenHandler.getAccumulatedRbtcBalance();
        // vm.prank(OWNER);
        // address user = dcaManager.getUsers()[0]; // Only one user in this test, but several schedules
        // uint256 numOfPurchases = dcaManager.ownerGetUsersDcaSchedules(user, address(mockDocToken)).length;
        address[] memory users = new address[](NUM_OF_SCHEDULES);
        uint256[] memory scheduleIndexes = new uint256[](NUM_OF_SCHEDULES);
        uint256[] memory purchaseAmounts = new uint256[](NUM_OF_SCHEDULES);
        uint256[] memory purchasePeriods = new uint256[](NUM_OF_SCHEDULES);

        uint256 totalNetPurchaseAmount;

        // Create the arrays for the batch purchase (in production, this is done in the back end)
        for (uint8 i; i < NUM_OF_SCHEDULES; ++i) { 
            uint256 scheduleIndex = i;
            vm.startPrank(USER);
            uint256 schedulePurchaseAmount = dcaManager.getSchedulePurchaseAmount(address(mockDocToken), scheduleIndex);
            uint256 schedulePurchasePeriod = dcaManager.getSchedulePurchasePeriod(address(mockDocToken), scheduleIndex);
            vm.stopPrank();
            uint256 fee = feeCalculator.calculateFee(schedulePurchaseAmount, schedulePurchasePeriod);
            totalNetPurchaseAmount += schedulePurchaseAmount - fee;
            
            users[i] = USER; // Same user for has 5 schedules due for a purchase in this scenario
            scheduleIndexes[i] = i;
            vm.startPrank(OWNER);
            purchaseAmounts[i] = dcaManager.ownerGetUsersDcaSchedules(users[0], address(mockDocToken))[i].purchaseAmount;
            purchasePeriods[i] = dcaManager.ownerGetUsersDcaSchedules(users[0], address(mockDocToken))[i].purchasePeriod;
            vm.stopPrank();
        }
        for (uint8 i; i < NUM_OF_SCHEDULES; ++i) { 
            vm.expectEmit(false, false, false, false);
            emit TokenHandler__RbtcBought(USER, address(mockDocToken), 0, 0); // Never mind the actual values on this test
        }
        vm.expectEmit(true, true, true, false);
        emit TokenHandler__SuccessfulRbtcBatchPurchase(address(mockDocToken), totalNetPurchaseAmount / BTC_PRICE, totalNetPurchaseAmount);
        vm.prank(OWNER);
        dcaManager.batchBuyRbtc(users, address(mockDocToken), scheduleIndexes, purchaseAmounts, purchasePeriods);

        uint256 postDocTokenHandlerBalance = address(docTokenHandler).balance;

        // The balance of the DOC token handler contract gets incremented in exactly the purchased amount of rBTC
        assertEq(postDocTokenHandlerBalance - prevDocTokenHandlerBalance, totalNetPurchaseAmount / BTC_PRICE); 

        vm.prank(USER);
        uint256 userAccumulatedRbtcPost = docTokenHandler.getAccumulatedRbtcBalance();
        // The user's balance is also equal (since we're batching the purchases of 5 schedules but only one user)
        assertEq(userAccumulatedRbtcPost - userAccumulatedRbtcPrev, totalNetPurchaseAmount / BTC_PRICE); 

        vm.warp(block.timestamp + 5 weeks); // warp to a time far in the future so all schedules are long due for a new purchase
        vm.prank(OWNER);
        dcaManager.batchBuyRbtc(users, address(mockDocToken), scheduleIndexes, purchaseAmounts, purchasePeriods);
        uint256 postDocTokenHandlerBalance2 = address(docTokenHandler).balance;
        // After a second purchase, we have the same increment
        assertEq(postDocTokenHandlerBalance2 - postDocTokenHandlerBalance, totalNetPurchaseAmount / BTC_PRICE); 
    }
}
