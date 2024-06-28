import {
	Button,
	Card,
	CircularProgress,
	Divider,
	Stack,
	Typography,
} from '@mui/material';
import { useContext, useState } from 'react';
import { Web3Context } from '../../context/Web3Context';

import { listaCantidad, listaDuracion, listaFrequencia } from './utils-dca';
import ExplorerLink from '../explorer/ExplorerLink';
import DCAManagerService from '../../application/DCAManagerService';
import { DCASelectForm } from './DCASelectForm';
import { DCAInputForm } from './DCAInputForm';

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
			const dcaManagerService = new DCAManagerService(provider);
			const tx = await dcaManagerService.createDcaSchedule('DOC', {
				cantidad,
				frequencia,
				duracion,
			});
			setTxPosition(tx);
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
					<DCAInputForm
						value={cantidad}
						listOfTogles={listaCantidad}
						initValue={0}
						onHandlerSelect={setCantidad}
					/>
					<DCASelectForm
						label={'Frequencia'}
						listOfTogles={listaFrequencia}
						onHandlerSelect={setFrequencia}
						initValue={0}
					/>
					<DCASelectForm
						label={'Duración'}
						listOfTogles={listaDuracion}
						onHandlerSelect={setDuracion}
						initValue={0}
					/>
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
