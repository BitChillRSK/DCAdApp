import { Card, Stack, Typography } from '@mui/material';
import TableActividad from '../components/actividad/TableActividad';
import useEventsActividad from '../hooks/actividad/useEventsActividad';
import { textoDuracion, textoFrecuencia } from '../components/dca/utils-dca';
import Withdraw from './../components/withdraw/Withdraw';

import { useLocation, useParams } from 'react-router-dom';

export default function Actividad() {
	const { rows, isLoading, comprado, gastado } = useEventsActividad();

	const { index } = useParams();
	const location = useLocation();
	const { tokenBalance, purchasePeriod, duracion, tokenAddress } =
		location.state || {};

	return (
		<div
			style={{
				display: 'flex',
				flexDirection: 'column',
				alignItems: 'center',
				width: '100%',
			}}
		>
			<Card
				sx={{
					padding: '50px',
					width: '610px',
					borderRadius: '50px',
					flexShrink: 0,
					backgroundColor: '#F7F7F7',
				}}
			>
				<Stack direction={'column'} spacing={4}>
					<div>
						<Typography variant='h5'>Estrategia DCA</Typography>
						<Typography variant='h6' color={'primary'}>
							{tokenBalance} USD - {textoFrecuencia(purchasePeriod)} -{' '}
							{textoDuracion(duracion)}
						</Typography>
					</div>
					<div>
						<Withdraw index={Number(index)} tokenAddress={tokenAddress} />
					</div>
					<div>
						<Typography variant='h6'>Comprado: {comprado} rBTC</Typography>
						<Typography variant='h6'>Gastado: {gastado} USD</Typography>
					</div>
					<TableActividad rows={rows} isLoading={isLoading} />
				</Stack>
			</Card>
		</div>
	);
}
