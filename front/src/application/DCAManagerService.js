import { weiToUnit } from './EtherUtiles';
import { DCAManagerAdapter } from './../infraestructura/DCAManagerAdapter';

class DCAManagerService {
	constructor(provider) {
		this.dcaManagerAdapter = new DCAManagerAdapter(provider);
	}

	async getAllDCAsofUserByToken(tokenAddress) {
		const dcasUser =
			await this.dcaManagerAdapter.getAllDcasOfUserByTokenAddress(tokenAddress);
		return dcasUser.map(dca => {
			const tokenBalance = weiToUnit(dca.tokenBalance);
			const purchaseAmount = weiToUnit(dca.purchaseAmount);
			const purchasePeriod = weiToUnit(dca.purchasePeriod);
			const duracion = tokenBalance / purchaseAmount / purchasePeriod;
			const lastPurchaseTimestamp = weiToUnit(dca.lastPurchaseTimestamp);

			return {
				tokenBalance,
				purchaseAmount,
				purchasePeriod,
				duracion,
				lastPurchaseTimestamp,
			};
		});
	}

	async deleteDCASchedulerBytokenAndIndex(tokenAddress, index) {
		return await this.dcaManagerAdapter.deleteDcaScheduleByTokenAddressAndIndex(
			tokenAddress,
			index
		);
	}
}

export default DCAManagerService;
