require('dotenv').config();

const sslEnabled = process.env.DB_SSL === 'true';

const config = {
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'flow_space',
  password: process.env.DB_PASSWORD,
  port: Number(process.env.DB_PORT) || 5432,
  ssl: sslEnabled ? { rejectUnauthorized: false } : undefined,
};

module.exports = config;
