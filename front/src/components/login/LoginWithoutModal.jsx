import { useContext, useEffect } from 'react';
import { Web3AuthNoModal } from '@web3auth/no-modal';
import { EthereumPrivateKeyProvider } from '@web3auth/ethereum-provider';
import { CHAIN_NAMESPACES, WALLET_ADAPTERS } from '@web3auth/base';
import { OpenloginAdapter } from '@web3auth/openlogin-adapter';
import { MetamaskAdapter } from '@web3auth/metamask-adapter';
import { Web3Context } from '../../context/Web3Context';
import { useNavigate } from 'react-router-dom';
import {
	Button,
	Card,
	CardActions,
	Stack,
	TextField,
	Typography,
} from '@mui/material';

const clientId = import.meta.env.VITE_CLIENT_ID;
const explorerUrl = import.meta.env.VITE_EXPLORER_URL;
const rpcTarget = import.meta.env.VITE_RPC_TARGET;
function LoginWithoutModal() {
	const navigateTo = useNavigate();
	const { setProvider, web3auth, setWeb3auth } = useContext(Web3Context);

	useEffect(() => {
		const init = async () => {
			try {
				const chainConfig = {
					chainId: '0x1F',
					rpcTarget,
					chainNamespace: CHAIN_NAMESPACES.EIP155,
					displayName: 'RSK Testnet',
					ticker: 'tRBTC',
					tickerName: 'RSK Testnet',
					blockExplorer: explorerUrl,
				};
				const web3auth = new Web3AuthNoModal({
					clientId,
					chainConfig,
					web3AuthNetwork: 'sapphire_devnet',
				});

				const privateKeyProvider = new EthereumPrivateKeyProvider({
					config: { chainConfig },
				});

				const openloginAdapter = new OpenloginAdapter({
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
					privateKeyProvider,
				});
				web3auth.configureAdapter(openloginAdapter);
				setWeb3auth(web3auth);

				/**
				 * METAMASK
				 */
				const metamaskAdapter = new MetamaskAdapter({
					clientId,
					web3AuthNetwork: 'sapphire_devnet',
					chainConfig,
				});
				web3auth.configureAdapter(metamaskAdapter);

				await web3auth.init();
				setProvider(web3auth.provider);
				if (web3auth.connected) {
					navigateTo('/home');
				}
			} catch (error) {
				console.error(error);
			}
		};

		init();
	}, []);

	const login = async () => {
		if (!web3auth) {
			console.error('web3auth not initialized yet');
			return;
		}
		const web3authProvider = await web3auth.connectTo(
			WALLET_ADAPTERS.OPENLOGIN,
			{
				loginProvider: 'google',
			}
		);
		if (web3auth.connected) {
			navigateTo('/home');
		}
		setProvider(web3authProvider);
	};

	const loginWithSMS = async event => {
		event.preventDefault();
		if (!web3auth) {
			console.error('web3auth not initialized yet');
			return;
		}
		const form = new FormData(event.target);
		const tlf = form.get('phone');
		const web3authProvider = await web3auth.connectTo(
			WALLET_ADAPTERS.OPENLOGIN,
			{
				loginProvider: 'sms_passwordless',
				extraLoginOptions: {
					login_hint: `+34-${tlf}`,
				},
			}
		);
		if (web3auth.connected) {
			navigateTo('/home');
		}
		setProvider(web3authProvider);
	};

	const loginWithEmail = async event => {
		event.preventDefault();
		if (!web3auth) {
			console.error('web3auth not initialized yet');
			return;
		}
		const form = new FormData(event.target);
		const email = form.get('email');
		const web3authProvider = await web3auth.connectTo(
			WALLET_ADAPTERS.OPENLOGIN,
			{
				loginProvider: 'email_passwordless',
				extraLoginOptions: {
					login_hint: email,
				},
			}
		);
		if (web3auth.connected) {
			navigateTo('/home');
		}
		setProvider(web3authProvider);
	};

	const loginWallet = async () => {
		const web3authProvider = await web3auth.connectTo(WALLET_ADAPTERS.METAMASK);
		setProvider(web3authProvider);
		if (web3auth.connected) {
			navigateTo('/home');
		}
	};

	return (
		<Stack
			direction={'column'}
			alignItems={'center'}
			sx={{ marginTop: '15px' }}
		>
			<Typography>Iniciar sesión</Typography>
			<Card
				sx={{
					maxWidth: 300,
					display: 'flex',
					justifyContent: 'center',
					padding: '10px',
					marginTop: '15px',
				}}
			>
				<CardActions>
					<Stack spacing={2}>
						<Button
							onClick={loginWallet}
							variant='contained'
							color='primary'
							sx={{
								color: '#FFF',
								borderRadius: '50px',
							}}
						>
							Conectar con wallet
						</Button>
						<Button
							onClick={login}
							variant='contained'
							sx={{
								backgroundColor: '#F7F7F7',
								color: 'black',
								borderRadius: '50px',
							}}
						>
							Conectar con Google
						</Button>

						<form onSubmit={loginWithSMS}>
							<TextField
								placeholder='+34-123456789'
								type='text'
								name='phone'
								sx={{ marginTop: '5px', marginBottom: '5px' }}
								fullWidth
							/>
							<Button
								type='submit'
								variant='contained'
								fullWidth
								sx={{
									backgroundColor: '#F7F7F7',
									color: 'black',
									borderRadius: '50px',
								}}
							>
								Conectar con Teléfono
							</Button>
						</form>

						<form onSubmit={loginWithEmail}>
							<TextField
								placeholder='name@mail.com'
								type='email'
								name='email'
								sx={{ marginTop: '5px', marginBottom: '5px' }}
								fullWidth
							/>
							<Button
								type='submit'
								variant='contained'
								fullWidth
								sx={{
									backgroundColor: '#F7F7F7',
									color: 'black',
									borderRadius: '50px',
									':hover': '#FFB04B',
								}}
							>
								Conectar con Email
							</Button>
						</form>
					</Stack>
				</CardActions>
			</Card>
		</Stack>
	);
}

export default LoginWithoutModal;
