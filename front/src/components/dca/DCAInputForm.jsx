import { FormControl, InputAdornment, OutlinedInput } from '@mui/material';
import { Fragment } from 'react';
import DCAToggleGroup from './DCAToggleGroup';
import PropTypes from 'prop-types';

export const DCAInputForm = ({
	listOfTogles,
	onHandlerSelect,
	value,
	initValue,
}) => {
	return (
		<Fragment>
			<FormControl fullWidth sx={{ m: 1 }}>
				<OutlinedInput
					id='outlined-adornment-amount'
					startAdornment={<InputAdornment position='start'>$</InputAdornment>}
					onChange={e => onHandlerSelect(e.target.value)}
					value={value || ''}
				/>
			</FormControl>
			<DCAToggleGroup
				listOfTogles={listOfTogles}
				handlerSelect={onHandlerSelect}
				initValue={initValue}
			/>
		</Fragment>
	);
};

DCAInputForm.propTypes = {
	label: PropTypes.string,
	onHandlerSelect: PropTypes.func,
	initValue: PropTypes.number,
	listOfTogles: PropTypes.array,
	value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};
