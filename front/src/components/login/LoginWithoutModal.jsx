import { useContext, useEffect } from 'react';
import { WALLET_ADAPTERS } from '@web3auth/base';
import { Web3Context } from '../../context/Web3Context';
import { useNavigate } from 'react-router-dom';
import { Button, Card, CardActions, Stack, Typography } from '@mui/material';
import {
	loginAdapterConfig,
	metamaskAdapterConfig,
	web3AuthModalConfig,
} from './loginConfig';

function LoginWithoutModal() {
	const navigateTo = useNavigate();
	const { setProvider, web3auth, setWeb3auth } = useContext(Web3Context);

	useEffect(() => {
		const init = async () => {
			try {
				const web3auth = web3AuthModalConfig();

				const openloginAdapter = loginAdapterConfig();
				web3auth.configureAdapter(openloginAdapter);
				setWeb3auth(web3auth);

				/**
				 * METAMASK
				 */
				const metamaskAdapter = metamaskAdapterConfig();
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
					</Stack>
				</CardActions>
			</Card>
		</Stack>
	);
}

export default LoginWithoutModal;
