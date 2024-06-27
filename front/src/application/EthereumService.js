import EthereumAdapter from './../infraestructura/EthereumAdapter';

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

	async getTokenBalance(addressToken, abi) {
		const account = await this.ethereumAdapter.getAccount();
		const balance = await this.ethereumAdapter.getTokenBalance(
			addressToken,
			abi,
			account
		);
		return balance;
	}
}

export default EthereumService;
