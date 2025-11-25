const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');
const { authenticateToken, requireRole } = require('../middleware/auth');
const fileUploadService = require('../services/fileUploadService');

function toRepositoryFile(file) {
  const ext = path.extname(file.filename).replace('.', '').toLowerCase();
  const sizeInMB = Math.round((file.size / (1024 * 1024)) * 100) / 100;
  return {
    id: file.filename,
    name: file.originalName || file.filename,
    fileType: ext || 'file',
    uploaded_at: new Date(file.uploadDate).toISOString(),
    uploaded_by: 'system',
    size: file.size,
    size_in_mb: sizeInMB,
    description: '',
    tags: [],
    file_path: file.url,
    uploader_name: 'System',
  };
}

router.get('/', authenticateToken, async (req, res) => {
  try {
    const files = await fileUploadService.listFiles();
    const data = files.map(toRepositoryFile);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to list documents' });
  }
});

// Upload not implemented here; use /api/v1/files/upload instead

router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const files = await fileUploadService.listFiles();
    const file = files.find(f => f.filename === req.params.id);
    if (!file) return res.status(404).json({ success: false, error: 'Document not found' });
    res.json({ success: true, data: toRepositoryFile(file) });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to get document' });
  }
});

router.get('/:id/download', authenticateToken, async (req, res) => {
  try {
    const files = await fileUploadService.listFiles();
    const file = files.find(f => f.filename === req.params.id);
    if (!file) return res.status(404).json({ success: false, error: 'Document not found' });
    const rel = file.url.replace(fileUploadService.baseUrl, '').replace(/^\//, '');
    const filePath = path.resolve(fileUploadService.storageBasePath, rel || file.filename);
    if (!fs.existsSync(filePath)) return res.status(404).json({ success: false, error: 'File not found' });
    res.download(filePath, file.originalName || file.filename);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to download document' });
  }
});

router.get('/:id/preview', authenticateToken, async (req, res) => {
  try {
    const files = await fileUploadService.listFiles();
    const file = files.find(f => f.filename === req.params.id);
    if (!file) return res.status(404).json({ success: false, error: 'Document not found' });
    const ext = path.extname(file.filename).replace('.', '').toLowerCase();
    if (['txt', 'md', 'json', 'xml', 'csv'].includes(ext)) {
      const rel = file.url.replace(fileUploadService.baseUrl, '').replace(/^\//, '');
      const filePath = path.resolve(fileUploadService.storageBasePath, rel || file.filename);
      if (!fs.existsSync(filePath)) return res.status(404).json({ success: false, error: 'File not found' });
      const content = fs.readFileSync(filePath, 'utf8');
      return res.json({ success: true, data: { previewContent: content } });
    }
    return res.json({ success: true, data: { downloadUrl: file.url } });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to generate preview' });
  }
});

router.delete('/:id', authenticateToken, requireRole(['system_admin', 'project_manager']), async (req, res) => {
  try {
    const ok = await fileUploadService.deleteFile(req.params.id);
    if (!ok) return res.status(404).json({ success: false, error: 'File not found' });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Delete failed' });
  }
});

router.post('/:id/view', authenticateToken, async (req, res) => {
  try {
    // No-op for now; acknowledge view for audit compatibility
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to track view' });
  }
});

router.get('/:id/audit', authenticateToken, async (req, res) => {
  try {
    // Return empty audit trail for now
    res.json({ success: true, data: [] });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to load audit' });
  }
});

module.exports = router;