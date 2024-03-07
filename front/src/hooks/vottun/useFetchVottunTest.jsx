import { useEffect, useState } from 'react';

const backendEndpoint = `${
	import.meta.env.VITE_API_BACKEND_ENDPOINT
}/vottun/testnet`;

export const useFetchVottunTestnet = () => {
	const [isLoading, setIsLoading] = useState(false);
	const [testNet, setTestNet] = useState(null);
	const [error, setError] = useState(null);

	useEffect(() => {
		const getChainIds = async () => {
			setIsLoading(true);
			setError(null);
			try {
				const res = await fetch(backendEndpoint);
				const infoChains = await res.json();
				setTestNet(infoChains);
			} catch (err) {
				setError(err);
				console.error('error to get chains in vottun', err);
			} finally {
				setIsLoading(false);
			}
		};
		getChainIds();
	}, []);

	return { testNet, isLoading, error };
};
