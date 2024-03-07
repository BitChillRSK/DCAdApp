import { Link } from 'react-router-dom';
import Logout from '../logout/Logout';
import { Button, Typography } from '@mui/material';
import Withdraw from '../withdraw/Withdraw';

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
			<Button component={Link} to='/actividad'>
				<Typography sx={{ color: 'black' }}>Actividad</Typography>
			</Button>
			<Logout />
			<Withdraw />
		</aside>
	);
}
