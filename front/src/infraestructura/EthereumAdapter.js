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

	async getTokenBalance(tokenAddress, abi, account) {
		const contract = new ethers.Contract(tokenAddress, abi, this.provider);
		const balance = await contract.balanceOf(account);
		return ethers.utils.formatUnits(balance, 18);
	}
}

export default EthereumAdapter;
