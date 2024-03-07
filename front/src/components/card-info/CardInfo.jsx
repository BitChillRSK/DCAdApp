import { Card, CardContent, CardMedia, Typography } from '@mui/material';
import PropTypes from 'prop-types';

const CardInfo = ({ title, description, logo }) => {
	return (
		<Card
			sx={{
				backgroundColor: '#F7F7F7',
				borderRadius: '50px',
				maxWidth: '610px',
			}}
		>
			<CardContent sx={{ display: 'flex' }}>
				<div
					style={{
						marginRight: '32px',
						display: 'flex',
						alignItems: 'center',
					}}
				>
					<div
						style={{
							height: '98px',
							width: '98px',
							backgroundColor: '#FB8C00',
							display: 'flex',
							alignItems: 'center',
						}}
					>
						<CardMedia component='img' height='68' width='72' image={logo} />
					</div>
				</div>
				<div>
					<Typography variant='h5'>{title}</Typography>
					<Typography>{description}</Typography>
				</div>
			</CardContent>
		</Card>
	);
};

export default CardInfo;

CardInfo.propTypes = {
	title: PropTypes.string,
	description: PropTypes.string,
	logo: PropTypes.string,
};
