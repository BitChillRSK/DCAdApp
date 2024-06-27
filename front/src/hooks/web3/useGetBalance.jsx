import { useEffect, useContext, useState } from 'react';
import { Web3Context } from '../../context/Web3Context';
import EthereumService from '../../application/EthereumService';

import { ADDRESS } from './../../utils/contants';
import DOC_ABI from './../../abis/DocToken.json';

export default function useGetBalance(account) {
	const { provider } = useContext(Web3Context);
	const [balance, setBalance] = useState(0);
	useEffect(() => {
		const getBalance = async () => {
			if (provider && account) {
				try {
					const ethereumService = new EthereumService(provider);
					const balance = await ethereumService.getTokenBalance(
						ADDRESS.DOC_TOKEN,
						DOC_ABI.abi
					);
					setBalance(balance);
				} catch (err) {
					console.error(err);
				}
			}
		};

		getBalance();
	}, [account]);
	return { balance };
}
