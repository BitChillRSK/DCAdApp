import { ethers } from 'ethers';

const PROVIDER_GET_BLOCK_SOCKET = import.meta.env
	.VITE_GET_BLOCK_PROVIDER_SOCKET;

class EventsAdapter {
	constructor(tokenAddress, abi) {
		this.provider = new ethers.providers.WebSocketProvider(
			PROVIDER_GET_BLOCK_SOCKET
		);
		this.contract = new ethers.Contract(tokenAddress, abi, this.provider);
	}

	filterOnTransferTo(account) {
		return this.contract.filters.Transfer(null, account);
	}

	getContract() {
		return this.contract;
	}
}

export default EventsAdapter;
