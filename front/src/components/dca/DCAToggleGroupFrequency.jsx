import { Stack } from '@mui/material';
import { useState } from 'react';
import PropTypes from 'prop-types';
import DCAToggleButton from './ToggleButton';

export default function DCAToggleGroupFrequency() {
	const [value, setValue] = useState('');

	const handleAlignment = event => {
		setValue(event.target.value);
	};
	return (
		<>
			<Stack direction='row' spacing={4}>
				<DCAToggleButton
					value={'semanal'}
					label={'Semanal'}
					handleToggleButton={handleAlignment}
					isSelected={value === 'semanal'}
				/>
				<DCAToggleButton
					value={'quincenal'}
					label={'Quincenal'}
					handleToggleButton={handleAlignment}
					isSelected={value === 'quincenal'}
				/>
				<DCAToggleButton
					value={'mensual'}
					label={'Mensual'}
					handleToggleButton={handleAlignment}
					isSelected={value === 'mensual'}
				/>
			</Stack>
		</>
	);
}

DCAToggleGroupFrequency.propTypes = {
	label: PropTypes.string,
	handlerChecked: PropTypes.func,
};
