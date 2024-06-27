import { useContext } from 'react';
import { Web3Context } from '../../context/Web3Context';
import { ethers } from 'ethers';
import { TextField } from '@mui/material';
import { LoadingButton } from '@mui/lab';

import MOCK_DOCK_TOKEN_ABI from './../../abis/MockDocToken.json';

export const Faucet = () => {
	const { provider } = useContext(Web3Context);

	const addFounds = async event => {
		event.preventDefault();
		const form = new FormData(event.target);
		const address = form.get('address');
		const docAddress = form.get('doc_address');
		const provider3 = new ethers.providers.Web3Provider(provider);
		const signer = provider3.getSigner();

		const mockDockContract = new ethers.Contract(
			docAddress,
			MOCK_DOCK_TOKEN_ABI.abi,
			signer
		);
		const valueInWei = ethers.utils.parseUnits(
			'9999999999999999999999999',
			'wei'
		);
		await mockDockContract.mint(address, valueInWei);
	};

	return (
		<form
			onSubmit={addFounds}
			style={{
				display: 'flex',
				flexDirection: 'column',
				alignItems: 'flex-start',
			}}
		>
			<TextField
				placeholder='My Wallet'
				type='text'
				name='address'
				sx={{ marginTop: '5px', marginBottom: '5px' }}
				required
			/>
			<TextField
				placeholder='DOC ADDRESS'
				type='text'
				name='doc_address'
				sx={{ marginTop: '5px', marginBottom: '5px' }}
				required
			/>
			<LoadingButton
				loading={false}
				variant='contained'
				type='submit'
				sx={{
					backgroundColor: '#F7F7F7',
					color: 'black',
					borderRadius: '50px',
				}}
			>
				añadir fondos
			</LoadingButton>
		</form>
	);
};
