// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// import {IDocToken} from "./interfaces/IDocToken.sol";
// import {IkDocToken} from "./interfaces/IkDocToken.sol";
// import {ISwapExecutor} from "./interfaces/ISwapExecutor.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// // import {DcaManager} from "./DcaManager.sol";

// contract SwapExecutor is ISwapExecutor, Ownable {
//     //////////////////////
//     // Modifiers /////////
//     //////////////////////
//     modifier onlyMocProxy() {
//         if (msg.sender != address(i_mocProxy)) revert RbtcDca__OnlyMocProxyCanSendRbtcToDcaContract();
//         _;
//     }

//     //////////////////////
//     // Functions /////////
//     //////////////////////
//     constructor(address docTokenAddress, address mocProxyAddress) Ownable(msg.sender) {
//         i_docToken = IDocToken(docTokenAddress);
//         i_mocProxy = IMocProxy(mocProxyAddress);
//         // i_kdocToken = IkDocToken(kdocTokenAddress);
//     }

//     receive() external payable onlyMocProxy {}
// }
