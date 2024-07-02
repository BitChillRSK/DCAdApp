import { RubicWidget } from './../components/rubic-widget/RubicWidger';
export default function Intercambio() {
	return (
		<div
			style={{
				width: '100%',
				display: 'flex',
				justifyContent: 'center',
				flexDirection: 'column',
			}}
		>
			<h1>Intercambio</h1>
			<RubicWidget />
		</div>
	);
}
