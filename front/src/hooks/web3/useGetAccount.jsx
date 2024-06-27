import { useEffect, useContext, useState } from 'react';
import { Web3Context } from '../../context/Web3Context';
import Web3 from 'web3';

export default function useGetAccount() {
	const { provider } = useContext(Web3Context);
	const [accountReduce, setAccountReduce] = useState(null);
	const [account, setAccount] = useState(null);
	useEffect(() => {
		const getAccount = async () => {
			if (provider) {
				const web3 = new Web3(provider);

				// Get user's Ethereum public address
				const address = await web3.eth.getAccounts();
				const mainWallet = address[0];
				setAccount(mainWallet);
				const prefix = mainWallet.slice(0, 4);
				const suffix = mainWallet.slice(-4);
				const reduceWallet = `${prefix}...${suffix}`;
				setAccountReduce(reduceWallet);
			}
		};
		getAccount();
	}, []);

	return { account, accountReduce };
}
