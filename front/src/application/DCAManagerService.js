import { weiToUnit, unitToWei } from './EtherUtiles';
import DCAManagerAdapter from './../infraestructura/DCAManagerAdapter';
import TokenHandlerAdapter from '../infraestructura/TokenHandlerAdapter';
import { getTokenInfo } from '../utils/tokenInfo';
import {
	frecuenciaASegundos,
	segundosAFrequencia,
} from '../components/dca/utils-dca';

class DCAManagerService {
	constructor(provider) {
		this.provider = provider;
		this.dcaManagerAdapter = new DCAManagerAdapter(provider);
	}

	async getAllDCAsofUserByToken(tokenAddress) {
		const dcasUser =
			await this.dcaManagerAdapter.getAllDcasOfUserByTokenAddress(tokenAddress);
		return dcasUser.map(dca => {
			const tokenBalance = weiToUnit(dca.tokenBalance);
			const purchaseAmount = weiToUnit(dca.purchaseAmount);
			const purchasePeriod = segundosAFrequencia(weiToUnit(dca.purchasePeriod));
			const duracion =
				Number(tokenBalance) / Number(purchaseAmount) / Number(purchasePeriod);
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

	async createDcaSchedule(token, { cantidad, frequencia, duracion }) {
		const { address, abi, tokenHandlerAddress } = getTokenInfo(token);

		// approve token
		const tokenHandler = new TokenHandlerAdapter(this.provider, address, abi);
		const cantidadTotal = cantidad * frequencia * duracion;
		const depositAmount = unitToWei(cantidadTotal);
		await tokenHandler.tokenApprove(tokenHandlerAddress, depositAmount);

		// create dca
		const purchaseAmount = unitToWei(cantidad.toString());
		const segundosFrecuencia = frecuenciaASegundos(frequencia);
		const purchasePeriod = unitToWei(segundosFrecuencia.toString());

		return this.dcaManagerAdapter.createDcaSchedule(
			address,
			depositAmount,
			purchaseAmount,
			purchasePeriod
		);
	}
}

export default DCAManagerService;
