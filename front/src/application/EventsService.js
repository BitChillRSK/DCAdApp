import EventsAdapter from '../infraestructura/EventsAdapter';

import { getTokenInfo } from '../utils/tokenInfo';

class EventsService {
	constructor(token) {
		const { address, abi } = getTokenInfo(token);
		this.eventsAdapter = new EventsAdapter(address, abi);
	}

	getFilterTransferAccount(account) {
		const filter = this.eventsAdapter.filterOnTransferTo(account);
		const contract = this.eventsAdapter.getContract();
		return {
			contract,
			filter,
		};
	}
}

export default EventsService;
