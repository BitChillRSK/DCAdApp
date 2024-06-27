class EthereumService {
	constructor(etheruemAdapter) {
		this.etheruemAdapter = etheruemAdapter;
	}

	async getAccountDetails() {
		const mainWallet = await this.etheruemAdapter.getAccount();
		const prefix = mainWallet.slice(0, 4);
		const suffix = mainWallet.slice(-4);
		const reduceWallet = `${prefix}...${suffix}`;

		return {
			mainWallet,
			reduceWallet,
		};
	}
}

export default EthereumService;
