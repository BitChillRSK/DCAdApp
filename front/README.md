# BitChill - front

https://bitchill.hedasoftsolutions.es

## Instalacion

```bash
npm install
```

## Arrancar proyecto

crear fichero .env e incluir

```bash
# DCA Manager
VITE_DCA_MANAGER= address del DCA MANAGER

# DOC TOKEN
VITE_DOC_TOKEN_HANDLER= address token handler para DOC
VITE_DOC_TOKEN= address token DOC

# WEB3 AUTH
VITE_CLIENT_ID= CLIENT ID de WEB3 Auth
VITE_DISPLAY_NAME= nombre red
VITE_URL_RPC= url rpc
VITE_CHAIN_ID= chain id en hexadecimal
VITE_TICKER=tRBTC
VITE_TICKER_NAME=RSK Localhost
VITE_URL_EXPLORER= url del explorer


# EXPLORER
VITE_EXPLORER_URL= url explorer
VITE_GET_BLOCK_PROVIDER= url + /id de get block
```

Arrancamos el nodo

```bash
anvil
forge script script/DeployContracts.s.sol:DeployContracts --rpc-url  127.0.0.1:8545 --private-key <PRIVATE_KEY> --broadcast
```

```bash
npm run dev
```

## FAUCET

Se ha creado un componente faucet para uso en local,
si se quiere utilizar hay que incluir en el fichero **.env** la siguiente variable de entorno

```bash
VITE_ENV=development
```

```javascript
// faucet
const mockDockContract = new ethers.Contract(
	ADDRESS_MOCK_DOC,
	MOCK_DOCK_TOKEN_ABI.abi,
	signer
);
const valueInWei = ethers.utils.parseUnits('9999999999999999999999999', 'wei');
await mockDockContract.mint(
	'0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
	valueInWei
);
```
