import { useEffect, useContext, useState } from 'react';
import { Web3Context } from '../../context/Web3Context';
import EthereumService from '../../application/EthereumService';

export default function useGetAccount() {
	const { provider } = useContext(Web3Context);
	const [accountReduce, setAccountReduce] = useState(null);
	const [account, setAccount] = useState(null);
	useEffect(() => {
		const getAccount = async () => {
			if (provider) {
				const ethereumService = new EthereumService(provider);
				const { mainWallet, reduceWallet } =
					await ethereumService.getAccountDetails();
				setAccount(mainWallet);
				setAccountReduce(reduceWallet);
			}
		};
		getAccount();
	}, []);

	return { account, accountReduce };
}
