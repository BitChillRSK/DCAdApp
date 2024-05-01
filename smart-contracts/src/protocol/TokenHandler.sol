// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDocTokenContract.sol";
import "./interfaces/IMocProxyContract.sol";

contract TokenHandler is Ownable {
    IDocTokenContract private docToken;
    IMocProxyContract private mocProxy;
    mapping(address => bool) public authorized;

    event DocDeposited(address indexed user, uint256 amount);
    event DocWithdrawn(address indexed user, uint256 amount);
    event RbtcRedeemed(address indexed user, uint256 docAmount, uint256 rbtcAmount);

    error RbtcDca__OnlyMocProxyContractCanSendRbtcToDcaContract();

    constructor(address docTokenAddress, address mocProxyAddress) Ownable(msg.sender) {
        docToken = IDocTokenContract(docTokenAddress);
        mocProxy = IMocProxyContract(mocProxyAddress);
    }


    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == owner(), "Unauthorized");
        _;
    }

    modifier onlyMocProxy() {
        if (msg.sender != address(mocProxy)) revert RbtcDca__OnlyMocProxyContractCanSendRbtcToDcaContract();
        _;
    }

    receive() external payable onlyMocProxy{}

    function addAuthorized(address _addr) public onlyOwner {
        authorized[_addr] = true;
    }

    function removeAuthorized(address _addr) public onlyOwner {
        authorized[_addr] = false;
    }

    function depositDocToken(address user, uint256 amount) public {
        require(docToken.allowance(user, address(this)) >= amount, "Insufficient allowance");
        require(docToken.transferFrom(user, address(this), amount), "Transfer failed");
        emit DocDeposited(user, amount);
    }

    function withdrawDocToken(address user, uint256 amount) public {
        require(docToken.transfer(user, amount), "Transfer failed");
        emit DocWithdrawn(user, amount);
    }

    function redeemDocForRbtc(address user, uint256 docAmount) external returns (uint256) {
        mocProxy.redeemDocRequest(docAmount);
        uint256 balancePrev = address(this).balance;
        mocProxy.redeemFreeDoc(docAmount);
        uint256 balancePost = address(this).balance;    
        uint256 rbtcAmount = balancePost - balancePrev;

        emit RbtcRedeemed(user, docAmount, rbtcAmount);

        return rbtcAmount;
    }
}
