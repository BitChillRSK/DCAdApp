import { ethers } from 'ethers';

class EthereumAdapter {
	constructor(provider) {
		this.provider = new ethers.providers.Web3Provider(provider);
	}

	async getAccount() {
		const signer = this.provider.getSigner();
		const address = await signer.getAddress();
		return address;
	}
}

export default EthereumAdapter;
