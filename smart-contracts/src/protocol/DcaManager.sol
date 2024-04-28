// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./TokenHandler.sol";

contract DcaManager is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct DcaDetails {
        uint256 docBalance;
        uint256 docPurchaseAmount;
        uint256 purchasePeriod;
        uint256 lastPurchaseTimestamp;
        uint256 rbtcBalance;
    }

    mapping(address => DcaDetails) private s_dcaDetails;
    address[] private s_users;
    mapping(address => mapping(bytes32 => uint256)) public userSettings;

    // Standard settings keys
    bytes32 constant public BALANCE_KEY = keccak256("balance");
    bytes32 constant public PURCHASE_AMOUNT_KEY = keccak256("purchaseAmount");
    bytes32 constant public PURCHASE_PERIOD_KEY = keccak256("purchasePeriod");
    bytes32 constant public LAST_PURCHASE_TIMESTAMP_KEY = keccak256("lastPurchaseTimestamp");

    address public tokenHandlerAddress;

    event DocDeposited(address indexed user, uint256 amount);
    event DocWithdrawn(address indexed user, uint256 amount);
    event PurchaseAmountSet(address indexed user, uint256 purchaseAmount);
    event PurchasePeriodSet(address indexed user, uint256 purchasePeriod);
    event NewDcaScheduleCreated(address indexed user, uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod);
    event UserSettingUpdated(address indexed user, bytes32 key, uint256 value);

    function initialize(address _tokenHandlerAddress) public initializer {
        __Ownable_init();
        tokenHandlerAddress = _tokenHandlerAddress;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function createDcaSchedule(uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod) external {
        require(depositAmount > 0, "Deposit amount must be greater than zero");
        require(purchaseAmount > 0, "Purchase amount must be greater than zero");
        require(purchaseAmount <= depositAmount / 2, "Purchase amount must be lower than half of deposit");
        require(purchasePeriod > 0, "Purchase period must be greater than zero");

        DcaDetails storage userDetails = s_dcaDetails[msg.sender];
        userDetails.docBalance += depositAmount;
        userDetails.docPurchaseAmount = purchaseAmount;
        userDetails.purchasePeriod = purchasePeriod;
        userDetails.lastPurchaseTimestamp = block.timestamp;

        if (userDetails.docBalance == depositAmount) {  // New user setup
            s_users.push(msg.sender);
        }

        TokenHandler(tokenHandlerAddress).depositDocToken(msg.sender, depositAmount);
        emit NewDcaScheduleCreated(msg.sender, depositAmount, purchaseAmount, purchasePeriod);
    }

    function setPurchaseAmount(uint256 purchaseAmount) external {
        require(purchaseAmount > 0, "Purchase amount must be greater than zero");
        DcaDetails storage userDetails = s_dcaDetails[msg.sender];
        userDetails.docPurchaseAmount = purchaseAmount;
        emit PurchaseAmountSet(msg.sender, purchaseAmount);
    }

    function setPurchasePeriod(uint256 purchasePeriod) external {
        require(purchasePeriod > 0, "Purchase period must be greater than zero");
        DcaDetails storage userDetails = s_dcaDetails[msg.sender];
        userDetails.purchasePeriod = purchasePeriod;
        emit PurchasePeriodSet(msg.sender, purchasePeriod);
    }

    function withdrawDOC(uint256 withdrawalAmount) external {
        require(withdrawalAmount > 0, "Withdrawal amount must be greater than zero");
        DcaDetails storage userDetails = s_dcaDetails[msg.sender];
        require(userDetails.docBalance >= withdrawalAmount, "Withdrawal amount exceeds balance");
        userDetails.docBalance -= withdrawalAmount;
        TokenHandler(tokenHandlerAddress).withdrawDocToken(msg.sender, withdrawalAmount);
        emit DocWithdrawn(msg.sender, withdrawalAmount);
    }

    function setParameter(address user, bytes32 key, uint256 value) public onlyOwner {
        userSettings[user][key] = value;
        emit UserSettingUpdated(user, key, value);
    }

    // Getter functions
    function getUserDcaDetails(address user) external view onlyOwner returns (DcaDetails memory) {
        return s_dcaDetails[user];
    }

    function getUsers() external view onlyOwner returns (address[] memory) {
        return s_users;
    }
}