import { useEffect, useContext, useState } from 'react';
import { Web3Context } from '../../context/Web3Context';
import Web3 from 'web3';

import { ADDRESS } from './../../utils/contants';

const MIN_ABI = [
	{
		constant: true,
		inputs: [
			{
				name: 'account',
				type: 'address',
			},
		],
		name: 'balanceOf',
		outputs: [
			{
				name: 'balance',
				type: 'uint256',
			},
		],
		payable: false,
		stateMutability: 'view',
		type: 'function',
	},
];

export default function useGetBalance(account) {
	const { provider } = useContext(Web3Context);
	const [balance, setBalance] = useState(0);
	useEffect(() => {
		const getBalance = async () => {
			if (provider && account) {
				try {
					const web3 = new Web3(provider);

					const contrato = new web3.eth.Contract(MIN_ABI, ADDRESS.DOC_TOKEN);

					contrato.methods
						.balanceOf(account)
						.call()
						.then(balance => {
							const balanceEther = web3.utils.fromWei(balance, 'ether');
							setBalance(balanceEther);
						})
						.catch(console.error);
				} catch (err) {
					console.error(err);
				}
			}
		};

		getBalance();
	}, [account]);
	return { balance };
}
