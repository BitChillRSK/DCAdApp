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

	async getTokenBalance(addressToken, abi) {
		const account = await this.etheruemAdapter.getAccount();
		const balance = await this.etheruemAdapter.getTokenBalance(
			addressToken,
			abi,
			account
		);
		return balance;
	}
}

export default EthereumService;
