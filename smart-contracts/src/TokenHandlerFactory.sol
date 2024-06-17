// // SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
// import {ITokenHandlerFactory} from "./interfaces/ITokenHandlerFactory.sol";
// import {ITokenHandler} from "./interfaces/ITokenHandler.sol"; // This should be the interface if TokenHandler is abstract

// /**
//  * @title TokenHandlerFactory
//  * @dev Contract for creating and managing TokenHandler contracts
//  */
// contract TokenHandlerFactory is ITokenHandlerFactory, Ownable {
//     mapping(address stablecoin => address tokenHandler) private s_tokenHandlers;

//     constructor() Ownable() {}

//     /**
//      * Creates a new TokenHandler contract for a specific token.
//      * @param token The address of the token for which to create the handler.
//      * @param handlerImplementation The contract address of the TokenHandler implementation.
//      * @return handler The address of the newly created TokenHandler.
//      */
//     function createTokenHandler(address token, address handlerImplementation)
//         external
//         onlyOwner
//         returns (address handler)
//     {
//         require(s_tokenHandlers[token] == address(0), "TokenHandlerFactory: Handler already exists");
//         require(handlerImplementation != address(0), "TokenHandlerFactory: Invalid handler implementation address");

//         // Deploy a new TokenHandler using Create2 for predictable address calculation
//         bytes memory bytecode = abi.encodePacked(type(TokenHandler).creationCode, abi.encode(token));
//         bytes32 salt = keccak256(abi.encodePacked(token));
//         handler = Create2.deploy(0, salt, bytecode);

//         s_tokenHandlers[token] = handler;
//         emit TokenHandlerCreated(token, handler);
//         return handler;
//     }

//     /**
//      * Updates the TokenHandler for a specific token.
//      * @param token The address of the token whose handler is to be updated.
//      * @param newHandler The new handler's address.
//      */
//     function updateTokenHandler(address token, address newHandler) external onlyOwner {
//         require(newHandler != address(0), "TokenHandlerFactory: Invalid new handler address");
//         require(s_tokenHandlers[token] != address(0), "TokenHandlerFactory: Handler does not exist");

//         s_tokenHandlers[token] = newHandler;
//         emit TokenHandlerUpdated(token, newHandler);
//     }

//     /**
//      * Retrieves the address of the TokenHandler for a specific token.
//      * @param token The token whose handler address is requested.
//      * @return handler The address of the token's handler.
//      */
//     function getTokenHandler(address token) external view returns (address handler) {
//         return s_tokenHandlers[token];
//     }
// }
