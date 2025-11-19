const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Simple test endpoint
app.get('/api/v1/auth/me', (req, res) => {
  res.json({
    success: true,
    data: {
      id: 'test-user-id',
      email: 'test@example.com',
      name: 'Test User',
      role: 'teamMember'
    }
  });
});

// Simple login endpoint
app.post('/api/v1/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  // Simple test login - accept any credentials
  res.json({
    success: true,
    data: {
      token: 'test-jwt-token',
      user: {
        id: 'test-user-id',
        email: email || 'test@example.com',
        name: 'Test User',
        role: 'teamMember'
      }
    }
  });
});

// Simple documents endpoint
app.get('/api/v1/documents', (req, res) => {
  res.json({
    success: true,
    data: {
      documents: []
    }
  });
});

// Simple document upload endpoint
app.post('/api/v1/documents', (req, res) => {
  res.json({
    success: true,
    data: {
      id: 'test-doc-id',
      name: 'test-document.pdf',
      fileType: 'pdf',
      uploadDate: new Date().toISOString(),
      uploadedBy: 'test-user-id',
      size: 1024,
      description: 'Test document',
      uploader: 'Test User',
      sizeInMB: '1.00',
      filePath: '/uploads/test-document.pdf',
      tags: 'test,document',
      contentHash: 'test-hash'
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Test server running on port ${PORT}`);
  console.log(`📡 API endpoints available at http://localhost:${PORT}/api/v1/`);
});