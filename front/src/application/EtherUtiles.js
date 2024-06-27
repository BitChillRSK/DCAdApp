import { ethers } from 'ethers';

export const weiToUnit = weiValue => {
	return ethers.utils.formatUnits(weiValue, 18);
};

export const unitToWei = unitValue => {
	return ethers.utils.parseUnits(unitValue.toString(), 18);
};
