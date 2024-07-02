import { useEffect } from 'react';

export const RubicWidget = () => {
	useEffect(() => {
		const configuration = {
			from: 'USDT',
			to: 'RBTC',
			fromChain: 'ETH',
			toChain: 'ROOTSTOCK',
			amount: 0,
			iframe: 'flex',
			hideSelectionFrom: false,
			hideSelectionTo: false,
			theme: 'dark',
			language: 'es',
			injectTokens: {},
			slippagePercent: {
				instantTrades: 2,
				crossChain: 5,
			},
			crossChainIntegratorAddress: '',
			onChainIntegratorAddress: '',
		};
		Object.freeze(configuration);

		if (window.rubicWidget) {
			window.rubicWidget.init(configuration);
		}
	}, []);

	return (
		<div style={{ display: 'flex', justifyContent: 'center' }}>
			<div id='rubic-widget-root' style={{ width: '100%', height: '600px' }} />
		</div>
	);
};
