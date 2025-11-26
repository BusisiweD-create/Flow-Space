const fs = require('fs');
const fsp = fs.promises;
const path = require('path');

process.env.FILE_STORAGE_PATH = 'uploads-test';
process.env.FILE_BASE_URL = '/uploads-test';

const fileUploadService = require('../fileUploadService');

describe('fileUploadService', () => {
  beforeAll(async () => {
    await fsp.rm('uploads-test', { recursive: true, force: true });
  });

  afterAll(async () => {
    await fsp.rm('uploads-test', { recursive: true, force: true });
  });

  test('uploads file to base path', async () => {
    const file = { originalname: 'sample.pdf', buffer: Buffer.from('test'), size: 4, mimetype: 'application/pdf' };
    const result = await fileUploadService.uploadFile(file);
    expect(result && result.filename).toBeDefined();
    const target = path.join(fileUploadService.storageBasePath, result.filename);
    await fsp.access(target);
    const stat = await fsp.stat(target);
    expect(stat.isFile()).toBe(true);
  });

  test('uploads file to prefix path', async () => {
    const file = { originalname: 'report.pdf', buffer: Buffer.from('data'), size: 4, mimetype: 'application/pdf' };
    const result = await fileUploadService.uploadFile(file, 'reports');
    expect(result && result.filename).toBeDefined();
    const target = path.join(fileUploadService.storageBasePath, 'reports', result.filename);
    await fsp.access(target);
    const stat = await fsp.stat(target);
    expect(stat.isFile()).toBe(true);
  });
});
