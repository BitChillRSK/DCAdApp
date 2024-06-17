pragma solidity ^0.8.0;


interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract InterfaceChecker {
    // Función para verificar si un contrato en `addr` soporta la función con la firma dada `functionSignature`.
    function supportsFunction(address addr, bytes4 functionSignature) public view returns (bool) {
        (bool success, bytes memory data) = addr.staticcall(abi.encodeWithSelector(functionSignature));
        return success && data.length > 0;  // `success` será true si la función existe y no revierte
    }

    // Función de ejemplo para interactuar con un contrato externo suponiendo que soporta una interfaz
    function tryToCallFunction(address contractAddress) external {
        // Ejemplo de firma de función que esperamos que el contrato soporte
        bytes4 funcSig = bytes4(keccak256("someFunction()"));

        // Comprobamos primero si la función es soportada
        if (supportsFunction(contractAddress, funcSig)) {
            (bool success, ) = contractAddress.call(abi.encodeWithSelector(funcSig));
            require(success, "Llamada a funcion fallida");
        } else {
            revert("La funcion requerida no esta soportada");
        }
    }

    function checkERC165Support(address addr) public view returns (bool) {
        IERC165 target = IERC165(addr);
        // El ID de la interfaz de ERC165 es 0x01ffc9a7
        // Calculado como bytes4(keccak256('supportsInterface(bytes4)'))
        try target.supportsInterface(bytes4(keccak256('supportsInterface(bytes4)'))) {
            return true;
        } catch {
            return false;
        }
    }
}