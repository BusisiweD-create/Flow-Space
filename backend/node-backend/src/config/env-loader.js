const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

// Try a few sensible locations for a .env file (node-backend/.env, backend/.env, repo root)
const candidates = [
	path.resolve(__dirname, '..', '..', '.env'),            // node-backend/.env
	path.resolve(__dirname, '..', '..', '..', '.env'),       // backend/.env
	path.resolve(__dirname, '..', '..', '..', '..', '.env')  // repo root .env (fallback)
];

let loadedPath = null;
for (const p of candidates) {
	if (fs.existsSync(p)) {
		dotenv.config({ path: p });
		loadedPath = p;
		break;
	}
}

// If none found, fall back to default dotenv behaviour (will use process.env)
if (!loadedPath) {
	dotenv.config();
}

console.log('Environment variables loaded from:', loadedPath || 'process.env (none found)');
console.log('DATABASE_URL:', process.env.DATABASE_URL ? '*** (set)' : 'undefined');

module.exports = process.env;