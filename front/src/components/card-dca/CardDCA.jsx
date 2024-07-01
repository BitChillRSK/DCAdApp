import {
	Card,
	CardActions,
	CardContent,
	Button,
	Typography,
	IconButton,
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import PropTypes from 'prop-types';

import { textoDuracion, textoFrecuencia } from '../dca/utils-dca';

export const CardDCA = ({
	duracion,
	lastPurchaseTimestamp,
	purchaseAmount,
	purchasePeriod,
	tokenBalance,
	onDeleteClick,
	onActivityClick,
}) => {
	return (
		<Card sx={{ minWidth: 275, margin: '5px' }}>
			<CardContent>
				<Typography sx={{ fontSize: 14 }} color='text.secondary' gutterBottom>
					Balance: {tokenBalance}
				</Typography>
				<Typography sx={{ fontSize: 14 }} color='text.secondary' gutterBottom>
					Cantidad: {purchaseAmount}
				</Typography>
				<Typography sx={{ fontSize: 14 }} color='text.secondary' gutterBottom>
					Periodo: {textoFrecuencia(purchasePeriod)}
				</Typography>
				<Typography sx={{ fontSize: 14 }} color='text.secondary' gutterBottom>
					Duracion: {textoDuracion(duracion)}
				</Typography>
				<Typography sx={{ fontSize: 14 }} color='text.secondary' gutterBottom>
					última compra:
					{lastPurchaseTimestamp === '0.0'
						? ' Aún no se han realizado ninguna compra'
						: lastPurchaseTimestamp}
				</Typography>
			</CardContent>
			<CardActions sx={{ display: 'flex', justifyContent: 'space-between' }}>
				<IconButton
					aria-label='delete dca'
					color='error'
					onClick={onDeleteClick}
				>
					<DeleteIcon />
				</IconButton>
				<Button onClick={onActivityClick}>Detalles</Button>
			</CardActions>
		</Card>
	);
};

CardDCA.propTypes = {
	tokenBalance: PropTypes.string,
	purchaseAmount: PropTypes.string,
	purchasePeriod: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
	duracion: PropTypes.number,
	lastPurchaseTimestamp: PropTypes.string,
	onActivityClick: PropTypes.func.isRequired,
	onDeleteClick: PropTypes.func.isRequired,
};
