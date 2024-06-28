import { useState } from 'react';
import {
	Card,
	Stack,
	Typography,
	IconButton,
	Snackbar,
	Alert,
} from '@mui/material';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';

import useGetAccount from '../../hooks/web3/useGetAccount';
import useGetBalance from '../../hooks/web3/useGetBalance';
import Logo from '../logo/Logo';

import './header.css';

export default function Header() {
	const { account, accountReduce } = useGetAccount();
	const { balance } = useGetBalance(account);

	const [open, setOpen] = useState(false);

	const handleCopyClick = () => {
		if (account) {
			navigator.clipboard
				.writeText(account)
				.then(() => {
					setOpen(true);
				})
				.catch(err => {
					console.error('Error al copiar al portapapeles: ', err);
				});
		}
	};

	const handleClose = (_event, reason) => {
		if (reason === 'clickaway') {
			return;
		}
		setOpen(false);
	};

	return (
		<Stack
			direction={'row'}
			justifyContent={'space-between'}
			className='header_container'
		>
			<Logo />
			<Card
				className='card'
				sx={{
					borderRadius: '20px',
					backgroundColor: 'rgba(247, 247, 247, 0.20)',
				}}
			>
				<Stack
					direction={'row'}
					alignItems={'center'}
					justifyContent={'space-around'}
					className='card_container'
				>
					<Stack direction={'column'}>
						<Typography variant='body-1'>Saldo DOC</Typography>
						<Typography variant='h6'>{Number(balance).toFixed(2)}</Typography>
					</Stack>
					<Stack direction={'column'}>
						<Stack direction='row' alignItems='center'>
							<Typography variant='body1'>Billetera</Typography>
							<IconButton onClick={handleCopyClick} aria-label='copiar'>
								<ContentCopyIcon sx={{ fontSize: '15px' }} />
							</IconButton>
						</Stack>
						<Typography variant='h6'>
							{accountReduce ?? 'Loading...'}
						</Typography>
						<Snackbar
							open={open}
							autoHideDuration={3000}
							onClose={handleClose}
							anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
						>
							<Alert
								onClose={handleClose}
								severity='success'
								className='icon_copy'
							>
								Wallet copiada
							</Alert>
						</Snackbar>
					</Stack>
				</Stack>
			</Card>
		</Stack>
	);
}
