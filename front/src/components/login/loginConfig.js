import { CHAIN_NAMESPACES, WEB3AUTH_NETWORK } from '@web3auth/base';

import { EthereumPrivateKeyProvider } from '@web3auth/ethereum-provider';
import { Web3AuthNoModal } from '@web3auth/no-modal';

import { OpenloginAdapter } from '@web3auth/openlogin-adapter';
import { MetamaskAdapter } from '@web3auth/metamask-adapter';

const clientId = import.meta.env.VITE_CLIENT_ID;

const URL_RPC = import.meta.env.VITE_URL_RPC;
const CHAIN_ID = import.meta.env.VITE_CHAIN_ID;
const DISPLAY_NAME = import.meta.env.VITE_DISPLAY_NAME;
const TICKER = import.meta.env.VITE_TICKER;
const TICKER_NAME = import.meta.env.VITE_TICKER_NAME;
const URL_EXPLORER = import.meta.env.VITE_URL_EXPLORER;
const walletAdapter = import.meta.env.VITE_WALLET_ADAPTER;

const chainConfigWeb3Auth = {
	chainId: CHAIN_ID,
	rpcTarget: URL_RPC,
	chainNamespace: CHAIN_NAMESPACES.EIP155,
	displayName: DISPLAY_NAME,
	ticker: TICKER,
	tickerName: TICKER_NAME,
	blockExplorer: URL_EXPLORER,
};

const loginAdapter = {
	adapterSettings: {
		whiteLabel: {
			appName: 'Fuck Degens',
			appUrl: 'https://fuck-degens.io',
			defaultLanguage: 'en', // en, de, ja, ko, zh, es, fr, pt, nl
			mode: 'auto', // whether to enable dark mode. defaultValue: false
			theme: {
				primary: '#768729',
			},
			useLogoLoader: true,
		},
	},
	privateKeyProvider: new EthereumPrivateKeyProvider({
		config: { chainConfig: chainConfigWeb3Auth },
	}),
};

export const web3AuthModalConfig = () => {
	return new Web3AuthNoModal({
		clientId,
		chainConfig: chainConfigWeb3Auth,
		web3AuthNetwork: walletAdapter,
	});
};

export const loginAdapterConfig = () => {
	return new OpenloginAdapter(loginAdapter);
};

export const metamaskAdapterConfig = () => {
	return new MetamaskAdapter({
		clientId,
		web3AuthNetwork: WEB3AUTH_NETWORK.TESTNET,
		chainConfig: chainConfigWeb3Auth,
	});
};
