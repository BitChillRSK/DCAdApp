import { Skeleton, TableCell, TableRow } from '@mui/material';

export default function TableSkeleton() {
	return [...Array(5)].map((_, index) => (
		<TableRow
			key={index}
			sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
		>
			<TableCell>
				<Skeleton variant='rectangular' height={30} />
			</TableCell>
			<TableCell>
				<Skeleton variant='rectangular' height={30} />
			</TableCell>
			<TableCell>
				<Skeleton variant='rectangular' height={30} />
			</TableCell>
		</TableRow>
	));
}
