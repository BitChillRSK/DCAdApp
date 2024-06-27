import { Link } from 'react-router-dom';
import Logout from '../logout/Logout';
import { Button, Typography } from '@mui/material';
import { Faucet } from '../fucet/Faucet';

export default function Menu() {
	return (
		<aside
			style={{
				display: 'flex',
				flexDirection: 'column',
				alignItems: 'flex-start',
			}}
		>
			<Button component={Link} to='/home'>
				<Typography sx={{ color: 'black' }}>Inicio</Typography>
			</Button>
			<Button component={Link} to='/my-dcas'>
				<Typography sx={{ color: 'black' }}>My DCAs</Typography>
			</Button>
			<Logout />
			<Faucet />
		</aside>
	);
}
