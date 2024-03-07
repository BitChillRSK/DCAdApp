const { ethers } = require("ethers");
const cron = require("node-cron");
require("dotenv").config();

const rpcUrl = process.env.RPC_URL || "https://public-node.testnet.rsk.co";

// Configuración del proveedor y del contrato
const provider = new ethers.JsonRpcProvider(rpcUrl);
const contractAddress = process.env.WALLAT_DCA;
console.log("");
const abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "docTokenAddress",
        type: "address",
      },
      {
        internalType: "address",
        name: "mocProxyAddress",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "OwnableInvalidOwner",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "OwnableUnauthorizedAccount",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__CannotBuyIfPurchasePeriodHasNotElapsed",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__CannotWithdrawRbtcBeforeBuying",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__DepositAmountMustBeGreaterThanZero",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__DocDepositFailed",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__DocWithdrawalAmountExceedsBalance",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__DocWithdrawalAmountMustBeGreaterThanZero",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__DocWithdrawalFailed",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__NotEnoughDocAllowanceForDcaContract",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__OnlyMocProxyContractCanSendRbtcToDcaContract",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__PurchaseAmountMustBeGreaterThanZero",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__PurchaseAmountMustBeLowerThanHalfOfBalance",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__PurchasePeriodMustBeGreaterThanZero",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__RedeemDocRequestFailed",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__RedeemFreeDocFailed",
    type: "error",
  },
  {
    inputs: [],
    name: "RbtcDca__rBtcWithdrawalFailed",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "DocDeposited",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "DocWithdrawn",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "purchaseAmount",
        type: "uint256",
      },
    ],
    name: "PurchaseAmountSet",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "purchasePeriod",
        type: "uint256",
      },
    ],
    name: "PurchasePeriodSet",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "docAmount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "rbtcAmount",
        type: "uint256",
      },
    ],
    name: "RbtcBought",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "rbtcAmount",
        type: "uint256",
      },
    ],
    name: "rBtcWithdrawn",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "buyer",
        type: "address",
      },
    ],
    name: "buyRbtc",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "depositAmount",
        type: "uint256",
      },
    ],
    name: "depositDOC",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getDocBalance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getPurchaseAmount",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getPurchasePeriod",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getRbtcBalance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getTotalNumberOfDeposits",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getUsers",
    outputs: [
      {
        internalType: "address[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "purchaseAmount",
        type: "uint256",
      },
    ],
    name: "setPurchaseAmount",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "purchasePeriod",
        type: "uint256",
      },
    ],
    name: "setPurchasePeriod",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "withdrawAccumulatedRbtc",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "withdrawalAmount",
        type: "uint256",
      },
    ],
    name: "withdrawDOC",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    stateMutability: "payable",
    type: "receive",
  },
];

const privateKey = process.env.PRIVATE_KEY; // La del owner del contrato
const wallet = new ethers.Wallet(privateKey, provider); // Sustituye al Metamask
const rbtcDcaContract = new ethers.Contract(contractAddress, abi, wallet);

// Lista de direcciones de usuarios
// const userAddresses = ["0x226E865Ab298e542c5e5098694eFaFfe111F93D3"];

// async function checkAndExecuteBuys() {
//   try {
//     // Obtiene las direcciones de los usuarios que han depositado DOC
//     const userAddresses = await rbtcDcaContract.getUsers();

//     const arrayPromise = []
//     userAddresses.forEarch(address => {
//       arrayPromise.push(rbtcDcaContract.buyRbtc(address).catch(error => Promise.resolve()))
//     })

//     Promise.all(arrayPromise)
//     Promise.allSettled()

//     for (const userAddress of userAddresses) {
//       try {
//         console.log(
//           `Intentando ejecutar compra para la dirección: ${userAddress}`
//         );
//         const tx = await rbtcDcaContract.buyRbtc(userAddress);
//         await tx.wait();
//         console.log(
//           `Compra ejecutada para la dirección: ${userAddress}, tx: ${tx.hash}`
//         );
//       } catch (error) {
//         // Maneja el error específico de "periodo de compra no ha transcurrido"
//         if (error.message.includes("CannotBuyIfPurchasePeriodHasNotElapsed")) {
//           console.log(
//             `Todavía no es el momento de comprar para la dirección: ${userAddress}`
//           );
//         } else {
//           console.error(
//             `Error al ejecutar la compra para la dirección: ${userAddress}:`,
//             error
//           );
//         }
//       }
//     }
//   } catch (error) {
//     console.error("Error al obtener las direcciones de los usuarios:", error);
//   }
// }

async function checkAndExecuteBuys() {
  try {
    // Obtiene las direcciones de los usuarios que han depositado DOC
    const userAddresses = await rbtcDcaContract.getUsers();

    // Crea un array de promesas para ejecutar las compras para cada dirección
    const buyPromises = userAddresses.map((userAddress) => {
      console.log(
        `Intentando ejecutar compra para la dirección: ${userAddress}`
      );
      return rbtcDcaContract
        .buyRbtc(userAddress)
        .then((tx) => tx.wait()) // Espera a que la transacción se confirme
        .then((txReceipt) => ({
          status: "fulfilled",
          value: `Compra ejecutada para la dirección: ${userAddress}, tx: ${txReceipt.transactionHash}`,
          address: userAddress,
        }))
        .catch((error) => ({
          status: "rejected",
          reason: error,
          address: userAddress,
        }));
    });

    // Espera a que todas las promesas se resuelvan
    const results = await Promise.allSettled(buyPromises);

    // Maneja los resultados
    results.forEach((result) => {
      if (result.status === "fulfilled") {
        console.log(result.value);
      } else if (
        result.reason.message.includes("CannotBuyIfPurchasePeriodHasNotElapsed")
      ) {
        console.log(
          `Todavía no es el momento de comprar para la dirección: ${result.address}`
        );
      } else {
        console.error(
          `Error al ejecutar la compra para la dirección: ${result.address}:`,
          result.reason
        );
      }
    });
  } catch (error) {
    console.error("Error al obtener las direcciones de los usuarios:", error);
  }
}

// Programar la ejecución del bot

cron.schedule("0 * * * * *", () => {
  // Se ejecuta cada 15 segundos
  console.log("Verificando si es momento de ejecutar compras...");
  checkAndExecuteBuys();
});

console.log("Bot iniciado...");
