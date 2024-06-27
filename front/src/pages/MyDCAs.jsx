import { useEffect, useContext, useState } from 'react';
import { Web3Context } from '../context/Web3Context';
import { ethers } from 'ethers';

import { useNavigate } from 'react-router-dom';
import {
	segundosAFrequencia,
	textoDuracion,
	textoFrecuencia,
} from './../components/dca/utils-dca';

import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardContent from '@mui/material/CardContent';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import DeleteIcon from '@mui/icons-material/Delete';

import DCA_MANAGER_ABI from './../abis/DcaManager.json';
import { ADDRESS } from '../utils/contants';

export const MyDCAs = () => {
	const { provider } = useContext(Web3Context);
	const navigate = useNavigate();

	const [myDCAs, setMyDCAs] = useState([]);

	const getDCAsUser = async () => {
		if (provider) {
			const provider3 = new ethers.providers.Web3Provider(provider);
			const signer = provider3.getSigner();

			const dcaContract = new ethers.Contract(
				ADDRESS.DCA_MANAGER,
				DCA_MANAGER_ABI.abi,
				signer
			);
			try {
				const DCAsUser = await dcaContract.getMyDcaSchedules(ADDRESS.DOC_TOKEN);
				const formatDCA = DCAsUser.map(dca => {
					const tokenBalance = ethers.utils.formatUnits(dca.tokenBalance, 18);
					const purchaseAmount = ethers.utils.formatUnits(
						dca.purchaseAmount,
						18
					);
					const purchasePeriod = segundosAFrequencia(
						ethers.utils.formatUnits(dca.purchasePeriod, 18)
					);
					const duracion = tokenBalance / purchaseAmount / purchasePeriod;
					const lastPurchaseTimestamp = ethers.utils.formatUnits(
						dca.lastPurchaseTimestamp,
						18
					);

					return {
						tokenBalance,
						purchaseAmount,
						purchasePeriod,
						duracion,
						lastPurchaseTimestamp,
					};
				});
				setMyDCAs(formatDCA);
			} catch (error) {
				console.error('Error to get DCAs user', error);
			}
		}
	};

	useEffect(() => {
		getDCAsUser();
	}, []);

	const deleteDCA = async index => {
		if (provider) {
			const provider3 = new ethers.providers.Web3Provider(provider);
			const signer = provider3.getSigner();

			const dcaContract = new ethers.Contract(
				ADDRESS.DCA_MANAGER,
				DCA_MANAGER_ABI.abi,
				signer
			);

			try {
				const deleteDCA = await dcaContract.deleteDcaSchedule(
					ADDRESS.DCA_MANAGER,
					index
				);
				await deleteDCA.wait();
				getDCAsUser();
			} catch (error) {
				console.error(`Error al eliminar dca ${index}`, error);
			}
		}
	};

	const activityDCA = index => {
		const dcaDetail = myDCAs[index];
		navigate(`/actividad/${index}`, {
			state: {
				purchaseAmount: dcaDetail.purchaseAmount,
				tokenBalance: dcaDetail.tokenBalance,
				purchasePeriod: dcaDetail.purchasePeriod,
				lastPurchaseTimestamp: dcaDetail.lastPurchaseTimestamp,
				duracion: dcaDetail.duracion,
				tokenAddress: ADDRESS.DOC_TOKEN,
			},
		});
	};

	return (
		<div
			style={{
				display: 'flex',
				alignItems: 'center',
				flexWrap: 'wrap',
				width: '100%',
				margin: '10px',
			}}
		>
			{myDCAs.length > 0
				? myDCAs.map((dca, index) => (
						<Card sx={{ minWidth: 275, margin: '5px' }} key={index}>
							<CardContent>
								<Typography
									sx={{ fontSize: 14 }}
									color='text.secondary'
									gutterBottom
								>
									Balance: {dca.tokenBalance}
								</Typography>
								<Typography
									sx={{ fontSize: 14 }}
									color='text.secondary'
									gutterBottom
								>
									Cantidad: {dca.purchaseAmount}
								</Typography>
								<Typography
									sx={{ fontSize: 14 }}
									color='text.secondary'
									gutterBottom
								>
									Periodo: {textoFrecuencia(dca.purchasePeriod)}
								</Typography>
								<Typography
									sx={{ fontSize: 14 }}
									color='text.secondary'
									gutterBottom
								>
									Duracion: {textoDuracion(dca.duracion)}
								</Typography>
								<Typography
									sx={{ fontSize: 14 }}
									color='text.secondary'
									gutterBottom
								>
									última compra:
									{dca.lastPurchaseTimestamp === '0.0'
										? ' Aún no se han realizado ninguna compra'
										: dca.lastPurchaseTimestamp}
								</Typography>
							</CardContent>
							<CardActions
								sx={{ display: 'flex', justifyContent: 'space-between' }}
							>
								<IconButton
									aria-label='delete dca'
									color='error'
									onClick={() => deleteDCA(index)}
								>
									<DeleteIcon />
								</IconButton>
								<Button onClick={() => activityDCA(index)}>Detalles</Button>
							</CardActions>
						</Card>
				  ))
				: null}
		</div>
	);
};
