// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenHandler.sol";

contract DcaManager is Ownable {
    struct DcaDetails {
        uint256 docBalance;
        uint256 docPurchaseAmount;
        uint256 purchasePeriod;
        uint256 lastPurchaseTimestamp;
        uint256 rbtcBalance;
    }

    mapping(address => DcaDetails) private s_dcaDetails;
    address[] private s_users;
    mapping(address => bool) public authorized;

    TokenHandler public tokenHandler;

    event NewDcaScheduleCreated(address indexed user, uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod);
    event DcaExited(address indexed user, uint256 docWithdrawn, uint256 rbtcWithdrawn);
    event PurchaseUpdated(address indexed user, uint256 lastPurchaseTimestamp, uint256 rbtcAmount);

    constructor(address payable _tokenHandlerAddress) Ownable(msg.sender) {
        require(_tokenHandlerAddress != address(0), "TokenHandler address cannot be zero.");
        tokenHandler = TokenHandler(_tokenHandlerAddress);
    }

    receive() external payable {}

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == owner(), "Unauthorized");
        _;
    }

    function addAuthorized(address _addr) public onlyOwner {
        authorized[_addr] = true;
    }

    function removeAuthorized(address _addr) public onlyOwner {
        authorized[_addr] = false;
    }

    function createDcaSchedule(uint256 depositAmount, uint256 purchaseAmount, uint256 purchasePeriod) external {
        require(depositAmount > 0 && purchaseAmount > 0 && purchasePeriod > 0, "Invalid DCA parameters");
        require(purchaseAmount <= depositAmount / 2, "Purchase amount too high");

        DcaDetails storage userDetails = s_dcaDetails[msg.sender];
        userDetails.docBalance += depositAmount;
        userDetails.docPurchaseAmount = purchaseAmount;
        userDetails.purchasePeriod = purchasePeriod;
        userDetails.lastPurchaseTimestamp = block.timestamp;

        tokenHandler.depositDocToken(msg.sender, depositAmount);
        s_users.push(msg.sender);
        emit NewDcaScheduleCreated(msg.sender, depositAmount, purchaseAmount, purchasePeriod);
    }

    function exitDcaProtocol() external {
        DcaDetails storage userDetails = s_dcaDetails[msg.sender];
        require(userDetails.docBalance > 0 || userDetails.rbtcBalance > 0, "No funds to withdraw");

        if (userDetails.docBalance > 0) {
            tokenHandler.withdrawDocToken(msg.sender, userDetails.docBalance);
            userDetails.docBalance = 0;
        }
        if (userDetails.rbtcBalance > 0) {
            payable(msg.sender).transfer(userDetails.rbtcBalance);
            userDetails.rbtcBalance = 0;
        }

        emit DcaExited(msg.sender, userDetails.docBalance, userDetails.rbtcBalance);
    }

    function updatePurchaseDetails(address user, uint256 docAmount, uint256 rbtcAmount) external {
        DcaDetails storage userDetails = s_dcaDetails[user];
        userDetails.docBalance -= docAmount;
        userDetails.lastPurchaseTimestamp = block.timestamp;
        userDetails.rbtcBalance += rbtcAmount; 
    }

    function getMyDcaDetails() external view returns (DcaDetails memory) {
        return s_dcaDetails[msg.sender];
    }

    function getUsers() external view onlyOwner returns (address[] memory) {
        return s_users;
    }

    function getUserDcaDetails(address user) public view returns (DcaDetails memory) {
        return s_dcaDetails[user];
    }
}