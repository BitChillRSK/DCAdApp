import { useEffect } from 'react';

const backendEndpoint = `${
	import.meta.env.VITE_API_BACKEND_ENDPOINT
}/dextools/chains`;

export const useFetchDextoolsBlockchain = ({ sort, order, page, pageSize }) => {
	const [isLoading, setIsLoading] = useEffect(false);
	const [chains, setChains] = useEffect(null);
	const [error, setError] = useEffect(null);

	useEffect(() => {
		const getChains = async () => {
			setIsLoading(true);
			setError(null);
			try {
				const res = await fetch(backendEndpoint);
				const infoChains = await res.json();
				setChains(infoChains);
			} catch (err) {
				console.error('error to get chains in dextools', err);
				setError(err);
			} finally {
				setIsLoading(false);
			}
		};
		getChains();
	}, [sort, order, page, pageSize]);

	return { chains, isLoading, error };
};
