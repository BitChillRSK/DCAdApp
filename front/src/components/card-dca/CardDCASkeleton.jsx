import {
	Card,
	CardActions,
	CardContent,
	Button,
	Typography,
	IconButton,
	Skeleton,
} from '@mui/material';

export const CardSkeleton = () => {
	return (
		<Card sx={{ minWidth: 275, margin: '5px' }}>
			<CardContent>
				<Typography
					sx={{ fontSize: 14, display: 'flex' }}
					color='text.secondary'
					gutterBottom
				>
					Balance: <Skeleton width={80} />
				</Typography>
				<Typography
					sx={{ fontSize: 14, display: 'flex' }}
					color='text.secondary'
					gutterBottom
				>
					Cantidad: <Skeleton width={80} />
				</Typography>
				<Typography
					sx={{ fontSize: 14, display: 'flex' }}
					color='text.secondary'
					gutterBottom
				>
					Periodo: <Skeleton width={100} />
				</Typography>
				<Typography
					sx={{ fontSize: 14, display: 'flex' }}
					color='text.secondary'
					gutterBottom
				>
					Duracion: <Skeleton width={100} />
				</Typography>
				<Typography
					sx={{ fontSize: 14, display: 'flex' }}
					color='text.secondary'
					gutterBottom
				>
					última compra: <Skeleton width={200} />
				</Typography>
			</CardContent>
			<CardActions sx={{ display: 'flex', justifyContent: 'space-between' }}>
				<IconButton aria-label='delete dca' color='error'>
					<Skeleton variant='circular' width={40} height={40} />
				</IconButton>
				<Skeleton variant='rectangular' width={100} height={40}>
					<Button>Detalles</Button>
				</Skeleton>
			</CardActions>
		</Card>
	);
};
