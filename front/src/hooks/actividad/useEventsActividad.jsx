import { useEffect, useState } from 'react';

import { ethers } from 'ethers';
import useGetAccount from '../web3/useGetAccount';
import { ABI_DCA } from '../../components/dca/ABI_APPROVE';

const PROVIDER_GET_BLOCK = import.meta.env.VITE_GET_BLOCK_PROVIDER;
const DCA_ADDRESS = import.meta.env.VITE_DCA_ADDRESS;
const EVENT_NAME_BUY = 'RbtcBought';

export default function useEventsActividad() {
	const { account } = useGetAccount();

	const [rows, setRows] = useState([]);
	const [isLoading, setIsLoading] = useState(false);
	const [comprado, setComprado] = useState(0);
	const [gastado, setGastado] = useState(0);

	useEffect(() => {
		const getEventsDCAEthers = async () => {
			setIsLoading(true);
			try {
				const provider3 = new ethers.providers.JsonRpcProvider(
					PROVIDER_GET_BLOCK
				);
				const dcaContract = new ethers.Contract(
					DCA_ADDRESS,
					ABI_DCA,
					provider3
				);
				const currentBlockNumber = await provider3.getBlockNumber();
				const events = await dcaContract.queryFilter(
					dcaContract.filters[EVENT_NAME_BUY](account),
					0,
					currentBlockNumber
				);
				const processedData = await Promise.all(
					events.map(async event => {
						const block = await event.getBlock();
						const args = event.args;
						const date = new Date(block.timestamp * 1000);
						const year = date.getFullYear();
						const month = String(date.getMonth() + 1).padStart(2, '0');
						const day = String(date.getDate()).padStart(2, '0');
						const formattedDate = `${year}/${month}/${day}`;
						return {
							fecha: formattedDate,
							hash: event.transactionHash,
							rbtc: ethers.utils.formatEther(args[2]),
							docAmount: ethers.utils.formatEther(args[1]),
							estado: 'Comprado',
						};
					})
				);
				setRows(processedData);
				const compradoRBTC = processedData.reduce(
					(accumulator, object) => accumulator + parseFloat(object.rbtc),
					0
				);
				setComprado(compradoRBTC);
				const gastadoUSD = processedData.reduce(
					(accumulator, object) => accumulator + parseFloat(object.docAmount),
					0
				);

				setGastado(gastadoUSD);
			} catch (error) {
				console.error('error', error);
			} finally {
				setIsLoading(false);
			}
		};

		if (account) {
			getEventsDCAEthers();
		}
	}, [account]);

	return { rows, isLoading, comprado, gastado };
}
