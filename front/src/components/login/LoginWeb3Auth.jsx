import { useContext, useEffect, useState } from 'react';
import { Web3Auth } from '@web3auth/modal';
import { CHAIN_NAMESPACES } from '@web3auth/base';
import { OpenloginAdapter } from '@web3auth/openlogin-adapter';

import Web3 from 'web3';
import { Web3Context } from '../../context/Web3Context';
import { Button } from '@mui/material';

const clientId = import.meta.env.VITE_CLIENT_ID;
const URL_RPC = import.meta.env.VITE_URL_RPC;
const CHAIN_ID = import.meta.env.VITE_CHAIN_ID;
const DISPLAY_NAME = import.meta.env.VITE_DISPLAY_NAME;
const TICKER = import.meta.env.VITE_TICKER;
const TICKER_NAME = import.meta.env.VITE_TICKER_NAME;
const URL_EXPLORER = import.meta.env.VITE_URL_EXPLORER;

const web3auth = new Web3Auth({
	clientId, // get from https://dashboard.web3auth.io
	web3AuthNetwork: 'sapphire_devnet',
	chainConfig: {
		chainId: CHAIN_ID,
		rpcTarget: URL_RPC,
		chainNamespace: CHAIN_NAMESPACES.EIP155,
		displayName: DISPLAY_NAME,
		ticker: TICKER,
		tickerName: TICKER_NAME,
		blockExplorer: URL_EXPLORER,
	},
});

const openloginAdapter = new OpenloginAdapter({
	adapterSettings: {
		uxMode: 'popup',
	},
});

web3auth.configureAdapter(openloginAdapter);

function LoginWeb3Auth() {
	const { provider, setProvider } = useContext(Web3Context);
	const [isLogged, setLoggedIn] = useState(false);

	useEffect(() => {
		const init = async () => {
			try {
				await web3auth.initModal();
				setProvider(web3auth.provider);
				if (web3auth.connected) {
					setLoggedIn(true);
				}
			} catch (err) {
				console.error(err);
			}
		};

		init();
	}, []);

	const login = async () => {
		const web3authProvider = await web3auth.connect();
		setProvider(web3authProvider);
		if (web3auth.connected) {
			setLoggedIn(true);
		}
	};

	const getUserInfo = async () => {
		const user = await web3auth.getUserInfo();
		uiConsole(user);
	};

	const logout = async () => {
		await web3auth.logout();
		setProvider(null);
		setLoggedIn(false);
		uiConsole('logged out');
	};

	const getAccounts = async () => {
		if (!provider) {
			uiConsole('provider not initialized yet');
			return;
		}

		const web3 = new Web3(provider);

		// Get user's Ethereum public address
		const address = await web3.eth.getAccounts();
		uiConsole(address);
	};

	const getBalance = async () => {
		if (!provider) {
			uiConsole('provider not initialized yet');
			return;
		}
		const web3 = new Web3(provider);

		// Get user's Ethereum public address
		const address = (await web3.eth.getAccounts())[0];

		// Get user's balance in ether
		const balance = web3.utils.fromWei(
			await web3.eth.getBalance(address), // Balance is in wei
			'ether'
		);
		uiConsole(balance);
	};

	const signMessage = async () => {
		if (!provider) {
			uiConsole('provider not initialized yet');
			return;
		}
		const web3 = new Web3(provider);

		// Get user's Ethereum public address
		const fromAddress = (await web3.eth.getAccounts())[0];

		const originalMessage = 'YOUR_MESSAGE';

		// Sign the message
		const signedMessage = await web3.eth.personal.sign(
			originalMessage,
			fromAddress,
			'test password!' // configure your own password here.
		);
		uiConsole(signedMessage);
	};

	function uiConsole(...args) {
		const el = document.querySelector('#console>p');
		if (el) {
			el.innerHTML = JSON.stringify(args || {}, null, 2);
			console.log(...args);
		}
	}

	const loggedInView = (
		<>
			<div className='flex-container'>
				<div>
					<Button onClick={getUserInfo} variant='outlined'>
						Get User Info
					</Button>
				</div>
				<div>
					<Button onClick={getAccounts} variant='outlined'>
						Get Accounts
					</Button>
				</div>
				<div>
					<Button onClick={getBalance} variant='outlined'>
						Get Balance
					</Button>
				</div>
				<div>
					<Button onClick={signMessage} variant='outlined'>
						Sign Message
					</Button>
				</div>
				<div>
					<Button onClick={logout} color='secondary'>
						Log Out
					</Button>
				</div>
			</div>
		</>
	);

	const unloggedInView = (
		<button onClick={login} className='card'>
			Login
		</button>
	);

	return (
		<>
			<div className='container'>
				<h1>Login with Web3Auth Rootstock</h1>

				<div className='grid'>{isLogged ? loggedInView : unloggedInView}</div>
				<div id='console' style={{ whiteSpace: 'pre-line' }}>
					<p style={{ whiteSpace: 'pre-line' }}></p>
				</div>

				<footer className='footer'></footer>
			</div>
		</>
	);
}

export default LoginWeb3Auth;
