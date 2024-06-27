import { ethers } from 'ethers';

class TokenHandlerAdapter {
	constructor(provider, tokenAddress, abi) {
		this.provider = new ethers.providers.Web3Provider(provider);
		this.tokenAddress = tokenAddress;
		this.abi = abi;
	}

	async tokenApprove(address, amount) {
		const tokenHandlerContract = this._getTokenHandlerContract();
		const approveToken = await tokenHandlerContract.approve(address, amount);
		await approveToken.wait();
	}

	_getTokenHandlerContract() {
		const signer = this.provider.getSigner();
		return new ethers.Contract(this.tokenAddress, this.abi, signer);
	}
}

export default TokenHandlerAdapter;
