import {
	Button,
	Card,
	CircularProgress,
	Divider,
	FormControl,
	InputAdornment,
	OutlinedInput,
	Stack,
	Typography,
} from '@mui/material';
import DCAToggleGroup from './DCAToggleGroup';
import { useContext, useState } from 'react';
import { Web3Context } from '../../context/Web3Context';
import { ABI_APPROVE } from './ABI_APPROVE';
import { ethers } from 'ethers';

import DCA_MANAGER_ABI from './../../abis/DcaManager.json';
import { ADDRESS } from '../../utils/contants';

import {
	listaCantidad,
	listaDuracion,
	listaFrequencia,
	frecuenciaASegundos,
} from './utils-dca';
import ExplorerLink from '../explorer/ExplorerLink';

const DCAFrom = () => {
	const [cantidad, setCantidad] = useState(0);
	const [frequencia, setFrequencia] = useState(0);
	const [duracion, setDuracion] = useState(0);

	const { provider } = useContext(Web3Context);

	const [isLoading, setIsLoading] = useState(false);
	const [txPosition, setTxPosition] = useState(null);

	const deposit = async () => {
		setIsLoading(true);
		setTxPosition(null);

		try {
			/**
			 * use ethers to sign...
			 */
			const provider3 = new ethers.providers.Web3Provider(provider);
			const signer = await provider3.getSigner();

			// Direcciones del contrato del token
			const tokenContract = new ethers.Contract(
				ADDRESS.DOC_TOKEN,
				ABI_APPROVE,
				signer
			);
			const dcaContract = new ethers.Contract(
				ADDRESS.DCA_MANAGER,
				DCA_MANAGER_ABI.abi,
				signer
			);
			const cantidadTotal = cantidad * frequencia * duracion;

			/**
			 * El dock token debe dar approve al docTokenHandler
			 */

			const amount = ethers.utils.parseUnits(cantidadTotal.toString(), 18);
			const tx = await tokenContract.approve(ADDRESS.DOC_TOKEN_HANDLER, amount);

			// Wait for the transaction to be mined
			await tx.wait();

			const purchaseAmount = ethers.utils.parseUnits(cantidad.toString(), 18);
			const segundosFrecuencia = frecuenciaASegundos(frequencia);
			const frecuencia = ethers.utils.parseUnits(
				segundosFrecuencia.toString(),
				18
			);

			/* const gasEstimate = await dcaContract.estimateGas.createDcaSchedule(
				ADDRESS_MOCK_DOC,
				amount,
				cantidad,
				segundosFrecuencia
			);
			console.log('el gas calculado es:', gasEstimate);
			*/
			const dcaSchedule = await dcaContract.createDcaSchedule(
				ADDRESS.DOC_TOKEN,
				amount,
				purchaseAmount,
				frecuencia,
				{ gasLimit: 30000000 }
			);
			await dcaSchedule.wait();
			setTxPosition(dcaSchedule);
		} catch (error) {
			console.error('Error sending transaction:', error);
		} finally {
			setIsLoading(false);
		}
	};
	return (
		<div
			style={{
				display: 'flex',
				flexDirection: 'column',
				alignItems: 'center',
				width: '100%',
			}}
		>
			<Typography variant='h5' sx={{ margin: '14px' }}>
				Configura tu ahorro periódico
			</Typography>
			<Card
				sx={{
					padding: '50px',
					width: '610px',
					borderRadius: '50px',
					flexShrink: 0,
					backgroundColor: '#F7F7F7',
				}}
			>
				<Typography variant='h6'>Cantidad periódica (DOC)</Typography>

				<Stack direction={'column'} spacing={3}>
					<FormControl fullWidth sx={{ m: 1 }}>
						<OutlinedInput
							id='outlined-adornment-amount'
							startAdornment={
								<InputAdornment position='start'>$</InputAdornment>
							}
							onChange={e => setCantidad(e.target.value)}
							value={cantidad || ''}
						/>
					</FormControl>
					<DCAToggleGroup
						listOfTogles={listaCantidad}
						handlerSelect={setCantidad}
						initValue={0}
					/>
					<div>
						<Typography variant='h6'>Frecuencia</Typography>
						<DCAToggleGroup
							listOfTogles={listaFrequencia}
							handlerSelect={setFrequencia}
							initValue={0}
						/>
					</div>
					<div>
						<Typography variant='h6'>Duración</Typography>
						<DCAToggleGroup
							listOfTogles={listaDuracion}
							handlerSelect={setDuracion}
							initValue={0}
						/>
					</div>
					<Divider />
					<div>
						<Typography variant='h5'>
							DOC a despositar: {cantidad * frequencia * duracion} $
						</Typography>
					</div>
					<div>
						{!isLoading && txPosition && (
							<ExplorerLink hash={txPosition.hash} />
						)}
					</div>
				</Stack>
			</Card>
			<div style={{ marginTop: '34px' }}>
				{isLoading ? (
					<CircularProgress />
				) : (
					<Button
						variant='contained'
						sx={{ width: '281px', height: '61px' }}
						onClick={deposit}
					>
						Depositar
					</Button>
				)}
			</div>
		</div>
	);
};

export default DCAFrom;
