import { useEffect, useContext, useState } from 'react';
import { Web3Context } from '../context/Web3Context';

import { useNavigate } from 'react-router-dom';
import { CardDCA } from './../components/card-dca/CardDCA';

import { ADDRESS } from '../utils/contants';

import DCAManagerAdapter from './../infraestructura/DCAManagerAdapter';
import DCAManagerService from './../application/DCAManagerService';
import { CardSkeleton } from '../components/card-dca/CardDCASkeleton';
import { CardNewDCA } from '../components/card-dca/CardNewDCA';

let adapter;
let dcaManagerService;

export const MyDCAs = () => {
	const { provider } = useContext(Web3Context);
	const navigate = useNavigate();

	const [myDCAs, setMyDCAs] = useState([]);
	const [isLoading, setIsLoading] = useState(false);

	const getDCAsUser = async () => {
		if (dcaManagerService) {
			setIsLoading(true);
			try {
				const formatDCA = await dcaManagerService.getAllDCAsofUserByToken(
					ADDRESS.DOC_TOKEN
				);
				setMyDCAs(formatDCA);
			} catch (error) {
				console.error('Error to get DCAs user', error);
			} finally {
				setIsLoading(false);
			}
		}
	};

	useEffect(() => {
		if (provider) {
			adapter = new DCAManagerAdapter(provider);
			dcaManagerService = new DCAManagerService(adapter);
			getDCAsUser();
		}
	}, [provider]);

	const deleteDCA = async index => {
		if (dcaManagerService) {
			try {
				await dcaManagerService.deleteDCASchedulerBytokenAndIndex(
					ADDRESS.DOC_TOKEN,
					index
				);
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
				justifyContent: 'center',
				alignItems: 'center',
				flexWrap: 'wrap',
				width: '100%',
				margin: '10px',
			}}
		>
			{isLoading
				? Array.from(new Array(5)).map((_, index) => (
						<CardSkeleton key={index} />
				  ))
				: null}
			{!isLoading && myDCAs.length > 0 ? (
				myDCAs.map((dca, index) => (
					<CardDCA
						key={index}
						tokenBalance={dca.tokenBalance}
						purchaseAmount={dca.purchaseAmount}
						purchasePeriod={dca.purchasePeriod}
						duracion={dca.duracion}
						lastPurchaseTimestamp={dca.lastPurchaseTimestamp}
						onActivityClick={() => activityDCA(index)}
						onDeleteClick={() => deleteDCA(index)}
					/>
				))
			) : (
				<CardNewDCA />
			)}
		</div>
	);
};
