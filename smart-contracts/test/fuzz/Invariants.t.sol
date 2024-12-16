// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DcaManager} from "src/DcaManager.sol";
import {AdminOperations} from "src/AdminOperations.sol";
import {DocTokenHandler} from "src/DocTokenHandler.sol";
// import {DocTokenHandlerDex} from "../../src/DocTokenHandlerDex.sol";
import {MockDocToken} from "../mocks/MockDocToken.sol";
import {MockKdocToken} from "../mocks/MockKdocToken.sol";
import {MockMocProxy} from "../mocks/MockMocProxy.sol";
import {DeployMocSwaps} from "../../script/DeployMocSwaps.s.sol";
import {MocHelperConfig} from "../../script/MocHelperConfig.s.sol";
import {Handler} from "./Handler.t.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../Constants.sol";

contract InvariantTest is StdInvariant, Test {
    DcaManager dcaManager;
    AdminOperations adminOperations;
    DocTokenHandler docTokenHandler;
    // DocTokenHandlerDex docTokenHandlerDex;
    MockDocToken mockDocToken;
    MockKdocToken mockKdocToken;
    MockMocProxy mockMocProxy;
    DeployMocSwaps deployer;
    MocHelperConfig helperConfig;
    Handler handler;
    uint256 constant NUM_USERS = 100;
    address[] public s_users;
    // address USER = makeAddr("user");
    address OWNER = makeAddr(OWNER_STRING);
    address ADMIN = makeAddr(ADMIN_STRING);
    address SWAPPER = makeAddr(SWAPPER_STRING);
    uint256 constant USER_TOTAL_DOC = 1_000_000 ether; // 1 million DOC owned by each user in total
    uint256 constant INITIAL_DOC_DEPOSIT = 1000 ether;
    uint256 constant INITIAL_PURCHASE_AMOUNT = 100 ether;
    uint256 constant INITIAL_PURCHASE_PERIOD = 1 weeks;
    uint256 constant MOC_START_RBTC_BALANCE = 500 ether;
    uint256 setUpTimestamp;

    function setUp() external {
        setUpTimestamp = block.timestamp;
        deployer = new DeployMocSwaps();
        (adminOperations, docTokenHandler, dcaManager, helperConfig) = deployer.run();

        (address docTokenAddress, address mocProxyAddress, address kDocTokenAddress) =
            helperConfig.activeNetworkConfig();

        mockDocToken = MockDocToken(docTokenAddress);
        mockKdocToken = MockKdocToken(kDocTokenAddress);

        vm.prank(OWNER);
        adminOperations.setAdminRole(ADMIN);
        vm.prank(ADMIN);
        adminOperations.setSwapperRole(SWAPPER);

        // Assign DOC token handler
        // vm.prank(OWNER);
        vm.prank(ADMIN);
        adminOperations.assignOrUpdateTokenHandler(docTokenAddress, address(docTokenHandler));

        // Initialize users and distribute 10000 DOC tokens
        for (uint256 i = 0; i < NUM_USERS; i++) {
            // address user = address(uint160(uint256(keccak256(abi.encodePacked("user", i)))));
            string memory userIndex = Strings.toString(i);
            string memory userLabel = string(abi.encodePacked("user", userIndex));
            address user = makeAddr(userLabel);
            // address user = makeAddr(string(abi.encodePacked("user", i)));
            // console.log(string(abi.encodePacked("user", i)));
            s_users.push(user);
            mockDocToken.mint(user, USER_TOTAL_DOC);
        }

        // Mint 10000 DOC for the user
        // mockDocToken.mint(USER, USER_TOTAL_DOC);

        // Deal rBTC to MoC proxy contract
        vm.deal(mocProxyAddress, MOC_START_RBTC_BALANCE);

        // Give the MoC proxy contract allowance to move DOC from docTokenHandler (this is mocking behaviour -> check that such approval is not necessary in production)
        vm.prank(address(docTokenHandler));
        mockDocToken.approve(mocProxyAddress, type(uint256).max);

        // Deploy the invariant tests handler contract and set it as target contract for the tests
        handler = new Handler(adminOperations, docTokenHandler, dcaManager, mockDocToken, s_users);
        targetContract(address(handler));

        // vm.startPrank(USER);
        // // Here we make the starting point of the invariant tests that the user has created a DCA schedule depositing 1000 DOC to spend 100 DOC every week
        // mockDocToken.approve(address(docTokenHandler), USER_TOTAL_DOC);
        // dcaManager.createOrUpdateDcaSchedule(docTokenAddress, 0, INITIAL_DOC_DEPOSIT, INITIAL_PURCHASE_AMOUNT, INITIAL_PURCHASE_PERIOD);
        // vm.stopPrank();

        // bytes4[] memory selectors = new bytes4[](2);
        // selectors[0] = Handler.despositDOC.selector;
        // selectors[1] = Handler.withdrawDOC.selector;
        // targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function invariant_kDocContractDocBalanceGreaterOrEqualsSumOfAllUsers() public {
        // get the total amount of DOC deposited in the kDOC contract
        // compare it to the sum of all users' balances
        vm.prank(OWNER);
        address[] memory users = dcaManager.getUsers();
        uint256 sumOfUsersDepositedDoc;
        for (uint256 i; i < users.length; ++i) {
            vm.startPrank(users[i]);
            uint256 numOfSchedules = dcaManager.getMyDcaSchedules(address(mockDocToken)).length;
            for (uint256 j; j < numOfSchedules; ++j) {
                sumOfUsersDepositedDoc += dcaManager.getScheduleTokenBalance(address(mockDocToken), j);
            }
            vm.stopPrank();
        }
        // DOC deposited in Bitchill is immediately lent in Tropykus
        assertEq(mockDocToken.balanceOf(address(docTokenHandler)), 0); // No DOC in DocTokenHandler

        // Update the amount of DOC in the mock kDOC contract according to the interest that has been generated
        uint256 interestFactor = 1e18 + (block.timestamp - setUpTimestamp) * 5 * 1e18 / (100 * 31536000); // 1 + timeInYears * yearlyIncrease
        uint256 currentDocBalanceInTropykus = mockDocToken.balanceOf(address(mockKdocToken));
        uint256 docToAdd = currentDocBalanceInTropykus * interestFactor / 1e18 - currentDocBalanceInTropykus;
        mockDocToken.mint(address(mockKdocToken), docToAdd);

        assertEq(mockDocToken.balanceOf(address(mockKdocToken)), sumOfUsersDepositedDoc); // All of the users's deposited DOC is in Tropykus
        // kDOC to DOC correspondence holds
        uint256 sumOfUsersKdoc;
        for (uint256 i; i < users.length; ++i) {
            sumOfUsersKdoc += docTokenHandler.getUsersKdocBalance(users[i]);
        }

        console.log("Interest Factor: ", interestFactor);
        console.log("exchangeRateStored: ", mockKdocToken.exchangeRateStored());
        console.log("sumOfUsersDepositedDoc: ", sumOfUsersDepositedDoc);
        console.log("sumOfUsersKdoc: ", sumOfUsersKdoc);
        console.log(
            "Total DOC in Tropykus: ", sumOfUsersKdoc * mockKdocToken.exchangeRateStored() / EXCHANGE_RATE_DECIMALS
        );

        assertGe(
            sumOfUsersKdoc * mockKdocToken.exchangeRateStored() / EXCHANGE_RATE_DECIMALS,
            // sumOfUsersDepositedDoc * interestFactor / 1e18
            sumOfUsersDepositedDoc
        );
        // console.log("Sum of users' DOC balances:", DepositedDoc);
        // console.log("DOC balance of the DOC token handler contract:", mockDocToken.balanceOf(address(docTokenHandler)));
    }

    function invariant_DocTokenHandlerRbtcBalanceNearlyEqualsSumOfAllUsers() public {
        // get the contract's rBTC balance and compare it to the sum of all users' balances
        vm.prank(OWNER);
        address[] memory users = dcaManager.getUsers();
        uint256 sumOfUsersBalances;
        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            sumOfUsersBalances += docTokenHandler.getAccumulatedRbtcBalance();
        }
        // We can't just user an assertEq because charging fees causes a slight precision loss
        assertApproxEqRel(
            address(docTokenHandler).balance,
            sumOfUsersBalances,
            0.0001e16 // Allow a maximum difference of 0.0001%
        );
        // assertGe(address(docTokenHandler).balance, sumOfUsersBalances); // The rBTC in the DOC token handler contract must be at least as much as the sum balances of the users
        // assertLe(address(docTokenHandler).balance * 9999 / 10000, sumOfUsersBalances); // The rBTC in the DOC token handler contract can only be slightly higher than the sum of balances (therefore, 99.99% of said rBTC should be lower than the sum)
        console.log("Sum of users' rBTC balances:", sumOfUsersBalances);
        console.log("rBTC balance of the DOC token handler contract:", address(docTokenHandler).balance);
    }

    // function invariant_gettersCantRevert() public {
    //     rbtcDca.getDocBalance();
    //     rbtcDca.getRbtcBalance();
    //     rbtcDca.getPurchaseAmount();
    //     rbtcDca.getPurchasePeriod();
    //     rbtcDca.getMyDcaDetails();
    //     vm.prank(OWNER);
    //     rbtcDca.ownerGetUsersDcaDetails(USER);
    //     vm.prank(OWNER);
    //     rbtcDca.getUsers();
    //     rbtcDca.getTotalNumberOfDeposits();
    // }

    function removeDuplicates(address[] memory arr) public pure returns (address[] memory) {
        uint256 length = arr.length;
        address[] memory result = new address[](length);
        uint256 index = 0;

        for (uint256 i = 0; i < length; i++) {
            bool isDuplicate = false;
            for (uint256 j = 0; j < i; j++) {
                if (arr[i] == arr[j]) {
                    isDuplicate = true;
                    break;
                }
            }
            if (!isDuplicate) {
                result[index] = arr[i];
                index++;
            }
        }

        address[] memory finalResult = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            finalResult[i] = result[i];
        }

        return finalResult;
    }
}
