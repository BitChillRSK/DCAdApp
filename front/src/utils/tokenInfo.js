import { ABI_APPROVE } from '../components/dca/ABI_APPROVE';
import { ADDRESS } from './contants';

const tokenInfo = {
	DOC: {
		address: ADDRESS.DOC_TOKEN,
		abi: ABI_APPROVE,
		tokenHandlerAddress: ADDRESS.DOC_TOKEN_HANDLER,
	},
};

export const getTokenInfo = token => {
	const info = tokenInfo[token] || undefined;
	if (!info) {
		throw new Error('Token not supported');
	}
	return info;
};
