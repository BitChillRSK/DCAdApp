import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './index.css';
import CssBaseline from '@mui/material/CssBaseline';

import '@fontsource/roboto/300.css';
import '@fontsource/roboto/400.css';
import '@fontsource/roboto/500.css';
import '@fontsource/roboto/700.css';
import { Container } from '@mui/material';
import { Web3Provider } from './context/Web3Context.jsx';

ReactDOM.createRoot(document.getElementById('root')).render(
	<>
		<CssBaseline />
		<Container>
			<Web3Provider>
				<App />
			</Web3Provider>
		</Container>
	</>
);
