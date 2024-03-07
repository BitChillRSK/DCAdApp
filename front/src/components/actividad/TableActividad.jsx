import {
	Paper,
	Table,
	TableBody,
	TableCell,
	TableContainer,
	TableHead,
	TableRow,
} from '@mui/material';
import TableSkeleton from './TableSkeleton';
import PropTypes from 'prop-types';
import TableNotBuy from './TableNotBuy';

export default function TableActividad({ isLoading, rows }) {
	return (
		<TableContainer component={Paper}>
			<Table aria-label='simple table'>
				<TableHead>
					<TableRow>
						<TableCell>Fecha</TableCell>
						<TableCell>Cantidad (rBTC)</TableCell>
						<TableCell>Estado</TableCell>
					</TableRow>
				</TableHead>
				<TableBody>
					{!isLoading &&
						rows.length > 0 &&
						rows.map((row, index) => (
							<TableRow
								key={index}
								sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
							>
								<TableCell component='th' scope='row'>
									{row.fecha}
								</TableCell>
								<TableCell>{row.rbtc}</TableCell>
								<TableCell>{row.estado}</TableCell>
							</TableRow>
						))}
					{isLoading && <TableSkeleton />}
					{!isLoading && rows.length === 0 && <TableNotBuy />}
				</TableBody>
			</Table>
		</TableContainer>
	);
}

TableActividad.propTypes = {
	isLoading: PropTypes.bool,
	rows: PropTypes.arrayOf(
		PropTypes.shape({
			fecha: PropTypes.string.isRequired,
			hash: PropTypes.string.isRequired,
			rbtc: PropTypes.string.isRequired,
			docAmount: PropTypes.string,
			estado: PropTypes.string.isRequired,
		})
	),
};
