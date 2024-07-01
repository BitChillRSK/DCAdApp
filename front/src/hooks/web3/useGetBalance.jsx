import { useEffect, useContext, useState } from 'react';
import { Web3Context } from '../../context/Web3Context';
import EthereumService from '../../application/EthereumService';
import EventsService from '../../application/EventsService';

export default function useGetBalance(account) {
	const { provider } = useContext(Web3Context);
	const [balance, setBalance] = useState(0);

	const getBalance = async () => {
		if (provider && account) {
			try {
				const ethereumService = new EthereumService(provider);
				const balance = await ethereumService.getTokenBalance('DOC', account);
				setBalance(balance);
			} catch (err) {
				console.error(err);
			}
		}
	};

	useEffect(() => {
		getBalance();
	}, [account]);

	useEffect(() => {
		const checkOnBalanceChange = async () => {
			if (provider && account) {
				const eventService = new EventsService('DOC');
				const { filter, contract } =
					eventService.getFilterTransferAccount(account);

				const onTransferAccount = async () => {
					getBalance();
				};

				contract.on(filter, onTransferAccount);
				return () => {
					contract.off(filter, onTransferAccount);
				};
			}
		};

		checkOnBalanceChange();
	}, [account]);

	return { balance };
}
