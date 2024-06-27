import {
	Card,
	CardContent,
	Typography,
	CardActions,
	Button,
} from '@mui/material';

export const CardNewDCA = () => {
	return (
		<Card sx={{ minWidth: 275, maxHeight: 150 }}>
			<CardContent>
				<Typography variant='h5' component='div'>
					Ahora no tienes ninguna DCA
				</Typography>
			</CardContent>
			<CardActions sx={{ display: 'flex', justifyContent: 'center' }}>
				<Button size='small'>Crear</Button>
			</CardActions>
		</Card>
	);
};
