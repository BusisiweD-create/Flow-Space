#!/usr/bin/env node
'use strict';

require('../src/config/env-loader');
const { sequelize } = require('../src/models');
const { QueryTypes } = require('sequelize');

(async () => {
  try {
    const rows = await sequelize.query(
      'SELECT id, recipient_id, sender_id, message, type, is_read, created_at FROM notifications ORDER BY created_at DESC LIMIT 10',
      { type: QueryTypes.SELECT }
    );
    console.log(JSON.stringify(rows, null, 2));
    process.exit(0);
  } catch (e) {
    console.error('List notifications error:', e);
    process.exit(1);
  }
})();