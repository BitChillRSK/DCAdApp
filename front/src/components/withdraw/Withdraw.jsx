import { useContext, useState } from 'react';
import PropTypes from 'prop-types';
import { ethers } from 'ethers';

import { Web3Context } from '../../context/Web3Context';
import { TextField } from '@mui/material';
import CurrencyExchangeIcon from '@mui/icons-material/CurrencyExchange';
import { LoadingButton } from '@mui/lab';
import ExplorerLink from '../explorer/ExplorerLink';
import DCA_MANAGER_ABI from './../../abis/DcaManager.json';
import { ADDRESS } from '../../utils/contants';

export default function Withdraw({ index, tokenAddress }) {
	const [isLoading, setIsLoading] = useState(false);
	const [txWithdraw, setTxWithdraw] = useState(null);
	const { provider } = useContext(Web3Context);

	const withdrawDeposit = async event => {
		event.preventDefault();
		setIsLoading(true);
		setTxWithdraw(null);
		if (!provider) {
			console.error('web3auth not initialized yet');
			return;
		}

		const form = new FormData(event.target);
		const withdrawDoC = form.get('withdrwaDoC');

		const provider3 = new ethers.providers.Web3Provider(provider);
		const signer = provider3.getSigner();
		const dcaContract = new ethers.Contract(
			ADDRESS.DCA_MANAGER,
			DCA_MANAGER_ABI.abi,
			signer
		);

		try {
			const withdrawAmount = ethers.utils.parseUnits(
				withdrawDoC.toString(),
				18
			);
			const withdraw = await dcaContract.withdrawToken(
				tokenAddress,
				index,
				withdrawAmount
			);
			await withdraw.wait();
			setTxWithdraw(withdraw);
		} catch (error) {
			console.error('Error al realizar withdraw', error);
		} finally {
			setIsLoading(false);
		}
	};

	return (
		<>
			<form
				onSubmit={withdrawDeposit}
				style={{
					display: 'flex',
					flexDirection: 'column',
					alignItems: 'flex-start',
				}}
			>
				<TextField
					placeholder='DoC'
					type='number'
					name='withdrwaDoC'
					sx={{ marginTop: '5px', marginBottom: '5px' }}
				/>
				<LoadingButton
					loading={isLoading}
					loadingPosition='end'
					variant='contained'
					type='submit'
					endIcon={<CurrencyExchangeIcon />}
					sx={{
						backgroundColor: '#F7F7F7',
						color: 'black',
						borderRadius: '50px',
					}}
				>
					Retirar DoC{' '}
				</LoadingButton>
			</form>
			{!isLoading && txWithdraw && <ExplorerLink hash={txWithdraw.hash} />}
		</>
	);
}

Withdraw.propTypes = {
	index: PropTypes.number,
	tokenAddress: PropTypes.string,
};
