export const listaCantidad = [
	{
		value: 50,
		label: '50 DOC',
	},
	{
		value: 100,
		label: '100 DOC',
	},
	{
		value: 200,
		label: '200 DOC',
	},
];

export const listaFrequencia = [
	{
		value: 4,
		label: 'Semanal',
	},
	{
		value: 2,
		label: 'Quincenal',
	},
	{
		value: 1,
		label: 'Mensual',
	},
];

export const listaDuracion = [
	{
		value: 12,
		label: '1 Año',
	},
	{
		value: 24,
		label: '2 Años',
	},
	{
		value: 60,
		label: '5 Años',
	},
];

const segundosMes = 2592000;

export const frecuenciaASegundos = frequencia => {
	return segundosMes / frequencia;
};
