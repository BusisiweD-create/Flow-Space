const express = require('express');
const app = express();

// Basic health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', message: 'Server is running' });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Test server running on port ${PORT}`);
  console.log('Health check available at: http://localhost:3000/health');
});