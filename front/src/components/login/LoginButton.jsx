import { Button } from '@mui/material';
import PropTypes from 'prop-types';

export const LoginButton = ({ label, onHandleClick, sx }) => {
	return (
		<Button onClick={onHandleClick} variant='contained' sx={sx}>
			{label}
		</Button>
	);
};

LoginButton.propTypes = {
	label: PropTypes.string,
	sx: PropTypes.object,
	onHandleClick: PropTypes.func.isRequired,
};
