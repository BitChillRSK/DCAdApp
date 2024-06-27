import { ethers } from 'ethers';
import { ADDRESS } from '../utils/contants';
import DCA_MANAGER_ABI from '../abis/DCAManager';

class DCAManagerAdapter {
	constructor(provider) {
		this.provider = new ethers.providers.Web3Provider(provider);
	}

	async getAllDcasOfUserByTokenAddress(tokenAddress) {
		const dcaContract = this._getContractDCAManager();
		try {
			return await dcaContract.getMyDcaSchedules(tokenAddress);
		} catch (error) {
			console.error(error);
			throw new Error('Error to get all the dcas for the token ', tokenAddress);
		}
	}

	async deleteDcaScheduleByTokenAddressAndIndex(tokenAddress, index) {
		const dcaContract = this._getContractDCAManager();
		try {
			const deleteDCA = await dcaContract.deleteDcaSchedule(
				tokenAddress,
				index
			);
			return deleteDCA.wait();
		} catch (error) {
			console.error(error);
			throw new Error(
				'Error to delete the dca schedule for token ',
				tokenAddress,
				' with index ',
				index
			);
		}
	}

	_getContractDCAManager() {
		const signer = this.provider.getSigner();
		return new ethers.Contract(
			ADDRESS.DCA_MANAGER,
			DCA_MANAGER_ABI.abi,
			signer
		);
	}
}

export default DCAManagerAdapter;