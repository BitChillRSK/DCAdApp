import EthereumAdapter from './../infraestructura/EthereumAdapter';
import { getTokenInfo } from '../utils/tokenInfo';

class EthereumService {
	constructor(provider) {
		this.ethereumAdapter = new EthereumAdapter(provider);
	}

	async getAccountDetails() {
		const mainWallet = await this.ethereumAdapter.getAccount();
		const prefix = mainWallet.slice(0, 4);
		const suffix = mainWallet.slice(-4);
		const reduceWallet = `${prefix}...${suffix}`;

		return {
			mainWallet,
			reduceWallet,
		};
	}

	async getTokenBalance(token, account) {
		const { address, abi } = getTokenInfo(token);
		const balance = await this.ethereumAdapter.getTokenBalance(
			address,
			abi,
			account
		);
		return balance;
	}
}

export default EthereumService;
