import PropTypes from 'prop-types';
import { Typography } from '@mui/material';
import DCAToggleGroup from './DCAToggleGroup';

export const DCASelectForm = ({
	label,
	listOfTogles,
	onHandlerSelect,
	initValue,
}) => {
	return (
		<div>
			<Typography variant='h6'>{label}</Typography>
			<DCAToggleGroup
				listOfTogles={listOfTogles}
				handlerSelect={onHandlerSelect}
				initValue={initValue}
			/>
		</div>
	);
};

DCASelectForm.propTypes = {
	label: PropTypes.string,
	onHandlerSelect: PropTypes.func,
	initValue: PropTypes.number,
	listOfTogles: PropTypes.array,
};
