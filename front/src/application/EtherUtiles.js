import { ethers } from 'ethers';

export const weiToUnit = weiValue => {
	return ethers.utils.formatUnits(weiValue, 18);
};
