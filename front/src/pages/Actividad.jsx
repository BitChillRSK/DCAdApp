import { Card, Stack, Typography } from '@mui/material';
import TableActividad from '../components/actividad/TableActividad';
import useEventsActividad from '../hooks/actividad/useEventsActividad';
import { useEffect, useContext } from 'react';
import { Web3Context } from '../context/Web3Context';
import { ethers } from 'ethers';
import { ABI_DCA } from '../components/dca/ABI_APPROVE';

const DCA_ADDRESS = import.meta.env.VITE_DCA_ADDRESS;

export default function Actividad() {
	const { rows, isLoading, comprado, gastado } = useEventsActividad();

	const { provider } = useContext(Web3Context);

	useEffect(() => {
		const getDcaDetails = async () => {
			const provider3 = new ethers.providers.Web3Provider(provider);
			const dcaContract = new ethers.Contract(DCA_ADDRESS, ABI_DCA, provider3);
			const details = await dcaContract.getMyDcaDetails();
			console.log('details', details);
			console.log('docBalance', ethers.utils.formatEther(details[0]));
			console.log('docPurchaseAmount', ethers.utils.formatEther(details[1]));
			console.log(
				'lastPurchaseTimestamp',
				ethers.utils.formatEther(details[2])
			);
			console.log('purchasePeriod', ethers.utils.formatEther(details[3]));
			console.log('rbtcBalance', ethers.utils.formatEther(details[4]));
		};

		getDcaDetails();
	}, []);

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
						<Typography variant='h5'>Estrategia DCA 1</Typography>
						<Typography variant='h6' color={'primary'}>
							12.000 USD - 24 compras - 2años
						</Typography>
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
