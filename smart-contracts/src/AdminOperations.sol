// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IAdminOperations} from "./interfaces/IAdminOperations.sol";
import {ITokenHandler} from "./interfaces/ITokenHandler.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
// import {InterfaceChecker} from "./InterfaceChecker.sol";
import {Test, console} from "forge-std/Test.sol";

/**
 * @title AdminOperations
 * @dev Contract to manage administrative tasks and token handlers
 */
contract AdminOperations is IAdminOperations, Ownable, AccessControl /* , InterfaceChecker */ {
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address token => address tokenHandlerContract) private s_tokenHandlers; 

    constructor() Ownable(msg.sender) {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Assigns a new TokenHandler to a token.
     * @param token The address of the token.
     * @param handler The address of the TokenHandler.
     */
    function assignOrUpdateTokenHandler(address token, address handler) public /*onlyRole(ADMIN_ROLE)*/ onlyOwner {
        if (!isContract(handler)) revert AdminOperations__EoaCannotBeHandler(handler);

        ITokenHandler tokenHandler = ITokenHandler(handler);

        if (tokenHandler.supportsInterface(type(ITokenHandler).interfaceId)) {
            s_tokenHandlers[token] = handler;
            emit AdminOperations__TokenHandlerUpdated(token, handler);
        } else {
            revert AdminOperations__ContractIsNotTokenHandler(handler);
        }
        // If a contract with no supportsInterface function is passed we will get an empty revert

        // This doesn't work because unhandled reverts (e. g., when the contract in the given address does not have the supportsInterface function) will not be caught
        // try tokenHandler.supportsInterface(type(ITokenHandler).interfaceId) returns (bool contractIsTokenHandler) {
        //     if(contractIsTokenHandler){
        //         s_tokenHandlers[token] = handler;
        //         emit AdminOperations__TokenHandlerUpdated(token, handler);
        //     } else revert AdminOperations__ContractIsNotTokenHandler(handler);
        // } catch {
        //     console.log("Catch");
        //     revert AdminOperations__ContractIsNotTokenHandler(handler);
        // }

    }

    /**
     * @dev Retrieves the handler for a given token.
     * @param token The address of the token.
     * @return The address of the TokenHandler. If address(0) is returned, the token is not accepted by the dApp.
     */
    function getTokenHandler(address token) public view returns (address) {
        return s_tokenHandlers[token];
    }

    /**
     * @dev Checks if a given address has a smart contract
     * @param addr The address of the token.
     */
    function isContract(address addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    // function supportsFunction(address contractAddress, bytes4 functionSignature) public view returns (bool) {
    //     (bool success, bytes memory data) = contractAddress.staticcall(abi.encodeWithSelector(functionSignature));
    //     return success && data.length > 0;  // success será true si la función existe y no revierte
    // }
}
