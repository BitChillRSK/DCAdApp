// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DcaManager} from "../../src/DcaManager.sol";
import {IDcaManager} from "../../src/interfaces/IDcaManager.sol";
import {ITokenHandler} from "../../src/interfaces/ITokenHandler.sol";
import {AdminOperations} from "src/AdminOperations.sol";
import {DocTokenHandler} from "src/DocTokenHandler.sol";
import {MockDocToken} from "../mocks/MockDocToken.sol";
import "../Constants.sol";
// import {MockMocProxy} from "../mocks/MockMocProxy.sol";

contract Handler is Test {
    AdminOperations public adminOperations;
    DocTokenHandler public docTokenHandler;
    DcaManager public dcaManager;
    MockDocToken public mockDocToken;
    // MockMocProxy public mockMocProxy;
    uint256 constant USER_TOTAL_DOC = 1_000_000 ether; // 1 million DOC owned by each user in total
    uint256 constant MAX_DEPOSIT_AMOUNT = 10_000 ether; // at most 10.000 DOC per deposit
    uint256 constant MIN_PURCHASE_AMOUNT = 10 ether; // at least 10 DOC in each periodic purchase
    uint256 constant MAX_PURCHASE_PERIOD = 520 weeks; // at least one purchase every 10 years
    uint256 constant MIN_PURCHASE_PERIOD = 1 days; // at most one purchase every day
    address OWNER = makeAddr(OWNER_STRING);
    // address USER = makeAddr("user");
    address[] public s_users;

    constructor(AdminOperations _adminOperations, DocTokenHandler _docTokenHandler, DcaManager _dcaManager, MockDocToken _mockDocToken, address[] memory users ) {
        adminOperations = _adminOperations;
        docTokenHandler = _docTokenHandler;
        dcaManager = _dcaManager;
        mockDocToken = _mockDocToken;
        s_users = users;
    }

    function depositDoc(uint256 userSeed, uint256 scheduleIndex, uint256 depositAmount) public {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        mockDocToken.mint(user, USER_TOTAL_DOC);
        if (depositAmount < 2 * MIN_PURCHASE_AMOUNT) {
            vm.stopPrank();
            return;
        }
        depositAmount = bound(depositAmount, 2 * MIN_PURCHASE_AMOUNT, MAX_DEPOSIT_AMOUNT);
        // if (depositAmount == 0) {
        //     vm.stopPrank();
        //     return;
        // }
        uint256 usersNumOfSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken)).length;
        if (usersNumOfSchedules == 0) {
            scheduleIndex = 0;
            // We need to create a DCA schedule before depositing more DOC 
            uint256 purchaseAmount = depositAmount / 10;
            purchaseAmount = bound(purchaseAmount, MIN_PURCHASE_AMOUNT, depositAmount / 2);
            mockDocToken.approve(address(docTokenHandler), depositAmount);
            dcaManager.createDcaSchedule(address(mockDocToken), depositAmount, purchaseAmount, MIN_PURCHASE_PERIOD);
        } else scheduleIndex = bound(scheduleIndex, 0, usersNumOfSchedules - 1);

        mockDocToken.approve(address(docTokenHandler), depositAmount);
        dcaManager.depositToken(address(mockDocToken), scheduleIndex, depositAmount);
        vm.stopPrank();
    }

    function withdrawDoc(uint256 userSeed, uint256 scheduleIndex, uint256 withdrawalAmount) public {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        uint256 usersNumOfSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken)).length;
        if (usersNumOfSchedules == 0) {
            scheduleIndex = 0;
            // We need to create a DCA schedule before withdrawing DOC 
            withdrawalAmount = bound(withdrawalAmount, 20 ether, MAX_DEPOSIT_AMOUNT / 10);
            uint256 depositAmount = 10 * withdrawalAmount;
            uint256 purchaseAmount;
            purchaseAmount = bound(purchaseAmount, MIN_PURCHASE_AMOUNT, depositAmount / 2);
            uint256 purchasePeriod = 3 days;
            mockDocToken.approve(address(docTokenHandler), depositAmount);
            dcaManager.createDcaSchedule(address(mockDocToken), depositAmount, purchaseAmount, purchasePeriod);
        } else scheduleIndex = bound(scheduleIndex, 0, usersNumOfSchedules - 1);

        uint256 maxWithdrawalAmount = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);
        withdrawalAmount = bound(withdrawalAmount, 0, maxWithdrawalAmount);
        if (withdrawalAmount == 0) {
            vm.stopPrank();
            return;
        }
        dcaManager.withdrawToken(address(mockDocToken), scheduleIndex, withdrawalAmount);
        vm.stopPrank();
    }

    function setPurchaseAmount(uint256 userSeed, uint256 scheduleIndex, uint256 purchaseAmount) external {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        uint256 usersNumOfSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken)).length;
        if (usersNumOfSchedules == 0) {
            scheduleIndex = 0;
            purchaseAmount = bound(purchaseAmount, MIN_PURCHASE_AMOUNT, MAX_DEPOSIT_AMOUNT / 10);
            // We need to create a DCA schedule before modifying the purchase amount
            uint256 depositAmount = purchaseAmount * 10;
            uint256 purchasePeriod = 3 days;
            mockDocToken.approve(address(docTokenHandler), depositAmount);
            dcaManager.createDcaSchedule(address(mockDocToken), depositAmount, purchaseAmount, purchasePeriod);
        } else scheduleIndex = bound(scheduleIndex, 0, usersNumOfSchedules - 1);

        uint256 maxPurchaseAmount = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex) / 2;
        if(maxPurchaseAmount < MIN_PURCHASE_AMOUNT) { // This can happen if the DOC balance left is less than 2 DOC
            vm.stopPrank();
            return;
        }
        purchaseAmount = bound(purchaseAmount, MIN_PURCHASE_AMOUNT, maxPurchaseAmount);
        if (purchaseAmount == 0) {
            vm.stopPrank();
            return;
        }
        dcaManager.setPurchaseAmount(address(mockDocToken), scheduleIndex, purchaseAmount);
        vm.stopPrank();
    }

    function setPurchasePeriod(uint256 userSeed, uint256 scheduleIndex, uint256 purchasePeriod) external {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        purchasePeriod = bound(purchasePeriod, MIN_PURCHASE_PERIOD, MAX_PURCHASE_PERIOD);
        uint256 usersNumOfSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken)).length;
        if (usersNumOfSchedules == 0) {
            scheduleIndex = 0;
            uint depositAmount = 1000 ether;
            uint purchaseAmount = 100 ether;
            // We need to create a DCA schedule before modifying the purchase period
            mockDocToken.approve(address(docTokenHandler), depositAmount);
            dcaManager.createDcaSchedule(address(mockDocToken), depositAmount, purchaseAmount, purchasePeriod);
        } else scheduleIndex = bound(scheduleIndex, 0, usersNumOfSchedules - 1);

        dcaManager.setPurchasePeriod(address(mockDocToken), scheduleIndex, purchasePeriod);
        vm.stopPrank();
    }

    function createDcaSchedule(uint256 userSeed, uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod) public {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        if (depositAmount < 2 * MIN_PURCHASE_AMOUNT) {
            vm.stopPrank();
            return;
        }
        depositAmount = bound(depositAmount, 2 * MIN_PURCHASE_AMOUNT, MAX_DEPOSIT_AMOUNT);
        purchaseAmount = bound(purchaseAmount, MIN_PURCHASE_AMOUNT, depositAmount / 2);
        purchasePeriod = bound(purchasePeriod, MIN_PURCHASE_PERIOD, MAX_PURCHASE_PERIOD);
        mockDocToken.approve(address(docTokenHandler), depositAmount);
        dcaManager.createDcaSchedule(address(mockDocToken), depositAmount, purchaseAmount, purchasePeriod);
        vm.stopPrank();
    }

    function updateDcaSchedule(uint256 userSeed, uint256 scheduleIndex, uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod) public {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        uint256 usersNumOfSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken)).length;
        if (usersNumOfSchedules == 0) { // If user has no schedules, update not possible
            vm.stopPrank();
            return;
        }
        scheduleIndex = bound(scheduleIndex, 0, usersNumOfSchedules - 1);
        depositAmount = bound(depositAmount, 0, MAX_DEPOSIT_AMOUNT);
        purchaseAmount = bound(purchaseAmount, 0, depositAmount / 2);
        purchasePeriod = bound(purchasePeriod, 0, MAX_PURCHASE_PERIOD);

        uint256 prevTokenBalance = dcaManager.getScheduleTokenBalance(address(mockDocToken), scheduleIndex);

        // Schedule parameters that are 0 don't get updated
        if(purchasePeriod < MIN_PURCHASE_PERIOD) purchasePeriod = 0; 
        if(purchaseAmount < MIN_PURCHASE_AMOUNT) purchaseAmount = 0;
        if(purchaseAmount > (prevTokenBalance + depositAmount) / 2) purchaseAmount = 0;

        mockDocToken.approve(address(docTokenHandler), depositAmount);
        dcaManager.updateDcaSchedule(address(mockDocToken), scheduleIndex, depositAmount, purchaseAmount, purchasePeriod);
        vm.stopPrank();
    }

    function deleteDcaSchedule(uint256 userSeed, uint256 scheduleIndex) public {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        uint256 usersNumOfSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken)).length;
        if (usersNumOfSchedules == 0) { // If user has no schedules, update not possible
            vm.stopPrank();
            return;
        }
        scheduleIndex = bound(scheduleIndex, 0, usersNumOfSchedules - 1);
        dcaManager.deleteDcaSchedule(address(mockDocToken), scheduleIndex);
        vm.stopPrank();
    }

    function buyRbtc(uint256 buyerAddressSeed, uint256 scheduleIndex) public {
        vm.prank(OWNER);
        address[] memory users = dcaManager.getUsers();
        if (users.length == 0) return;
        address buyer = users[buyerAddressSeed % users.length];

        vm.prank(buyer);
        IDcaManager.DcaDetails[] memory dcaDetails = dcaManager.getMyDcaSchedules(address(mockDocToken));
        uint256 usersNumOfSchedules = dcaDetails.length;
        if (usersNumOfSchedules == 0) return;
        scheduleIndex = bound(scheduleIndex, 0, usersNumOfSchedules - 1);

        if(dcaDetails[scheduleIndex].tokenBalance < dcaDetails[scheduleIndex].purchaseAmount) return;
        uint256 nextPurchaseTimestamp = dcaDetails[scheduleIndex].lastPurchaseTimestamp + dcaDetails[scheduleIndex].purchasePeriod;
        if(block.timestamp < nextPurchaseTimestamp) {            
            vm.warp(nextPurchaseTimestamp);
        }

        vm.prank(OWNER);
        dcaManager.buyRbtc(buyer, address(mockDocToken), scheduleIndex);
    }

    /**
     * @notice In this test we make purchases for all schedules of all users. In a real use case the script running on the back-end should find out which schedules are due for a purchase    
     */
    function batchBuyRbtc() external {
        vm.prank(OWNER);
        address[] memory users = dcaManager.getUsers();
        if (users.length == 0) return;
        console.log("Number of users", users.length);
        uint256 numOfPurchases = 0;

        for (uint256 i; i < users.length; ++i) {
            vm.prank(users[i]);
            IDcaManager.DcaDetails[] memory dcaSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken));
            for (uint256 j; j < dcaSchedules.length; ++j) {
                console.log("Purchase amount", dcaSchedules[j].purchaseAmount);
                console.log("Token balance", dcaSchedules[j].tokenBalance);
                if (dcaSchedules[j].tokenBalance >= dcaSchedules[j].purchaseAmount) {
                    numOfPurchases++;
                }
            }
        }

        // If all the users' schedules have been deleted numOfPurchases == 0
        if(numOfPurchases > 0) {
            address[] memory buyers = new address[](numOfPurchases);
            uint256[] memory scheduleIndexes = new uint256[](numOfPurchases);
            uint256[] memory purchaseAmounts = new uint256[](numOfPurchases);
            uint256[] memory purchasePeriods = new uint256[](numOfPurchases);
            uint256 furthestNextPurchaseTimestamp;
            uint256 buyersIndex = 0; 

            for(uint256 i; i < users.length; ++i){
                vm.prank(users[i]);
                IDcaManager.DcaDetails[] memory dcaSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken));
                for(uint256 j; j < dcaSchedules.length; ++j){
                    if (dcaSchedules[j].tokenBalance < dcaSchedules[j].purchaseAmount) continue;
                    buyers[buyersIndex] = users[i];
                    scheduleIndexes[buyersIndex] = j;
                    purchaseAmounts[buyersIndex] = dcaSchedules[j].purchaseAmount;
                    purchasePeriods[buyersIndex] = dcaSchedules[j].purchasePeriod;
                    if(furthestNextPurchaseTimestamp < dcaSchedules[j].lastPurchaseTimestamp + dcaSchedules[j].purchasePeriod) {
                        furthestNextPurchaseTimestamp = dcaSchedules[j].lastPurchaseTimestamp + dcaSchedules[j].purchasePeriod;
                    }
                    buyersIndex++;
                }
            }

            // Make sure that all the schedules are due for a purchase
            if(block.timestamp < furthestNextPurchaseTimestamp) {            
                vm.warp(furthestNextPurchaseTimestamp);
            }

            vm.prank(OWNER);
            dcaManager.batchBuyRbtc(buyers, address(mockDocToken), scheduleIndexes, purchaseAmounts, purchasePeriods);
        }
    }

    function withdrawRbtcFromTokenHandler(uint256 userSeed, uint256 tokenHandlerIndex) external {
        address user = s_users[userSeed % s_users.length];
        address[] memory depositedTokens = dcaManager.getUsersDepositedTokens(user);
        if(depositedTokens.length == 0) return;
        tokenHandlerIndex = bound(tokenHandlerIndex, 0, depositedTokens.length - 1);
        vm.startPrank(user);
        uint256 rbtcBalance = ITokenHandler(adminOperations.getTokenHandler(depositedTokens[tokenHandlerIndex])).getAccumulatedRbtcBalance();
        if (rbtcBalance == 0) {
            vm.stopPrank();
            return;
        }
        dcaManager.withdrawRbtcFromTokenHandler(depositedTokens[tokenHandlerIndex]);
        vm.stopPrank();
    }
    
    function withdrawAllRbtc(uint256 userSeed) external {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        address[] memory depositedTokens = dcaManager.getUsersDepositedTokens(user);
        if(depositedTokens.length == 0) {
            vm.stopPrank();
            return;
        }
        uint256 rbtcBalance = 0;
        for(uint256 i; i < depositedTokens.length; ++i){
            rbtcBalance += ITokenHandler(adminOperations.getTokenHandler(depositedTokens[i])).getAccumulatedRbtcBalance();
        }
        if (rbtcBalance == 0) {
            vm.stopPrank();
            return;
        }
        dcaManager.withdrawAllAccmulatedRbtc();
        vm.stopPrank();
    }

    function withdrawInterestFromDocTokenHandler(uint256 userSeed) external {
        address user = s_users[userSeed % s_users.length];
        vm.startPrank(user);
        dcaManager.withdrawInterestFromTokenHandler(address(mockDocToken));
        vm.stopPrank();
    }
}
