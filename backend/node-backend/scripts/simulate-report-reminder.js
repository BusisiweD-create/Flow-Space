#!/usr/bin/env node
'use strict';

require('../src/config/env-loader');
const { sequelize, User, Notification } = require('../src/models');
const { QueryTypes, Op } = require('sequelize');

async function run() {
  try {
    const args = process.argv.slice(2);
    const reportArgIndex = args.indexOf('--report');
    const reportId = reportArgIndex >= 0 ? args[reportArgIndex + 1] : null;
    const doCleanup = args.includes('--cleanup');

    if (doCleanup) {
      const targets = await sequelize.query(
        "SELECT id FROM sign_off_reports WHERE deliverable_id = $1 OR content::text LIKE $2",
        { bind: ['D-TEST', '%Test Report%'], type: QueryTypes.SELECT }
      );
      const ids = targets.map(r => r.id);
      const notifDel = await sequelize.query(
        "DELETE FROM notifications WHERE type = 'approval' AND message LIKE $1",
        { bind: ['%Test Report%'], type: QueryTypes.DELETE }
      );
      if (ids.length > 0) {
        await sequelize.query(
          `DELETE FROM sign_off_reports WHERE id IN (${ids.map((_, i) => '$' + (i + 1)).join(',')})`,
          { bind: ids, type: QueryTypes.DELETE }
        );
      }
      console.log(`Cleanup completed. Removed reports: ${ids.length}`);
      process.exit(0);
    }

    let reports;
    if (reportId) {
      reports = await sequelize.query(
        'SELECT id, created_by, status, content, updated_at FROM sign_off_reports WHERE id = $1',
        { bind: [reportId], type: QueryTypes.SELECT }
      );
    } else {
      reports = await sequelize.query(
        "SELECT id, created_by, status, content, updated_at FROM sign_off_reports WHERE status = 'submitted' ORDER BY updated_at DESC LIMIT 1",
        { type: QueryTypes.SELECT }
      );
    }

    if (!reports || reports.length === 0) {
      reports = await sequelize.query(
        'SELECT id, created_by, status, content, updated_at FROM sign_off_reports ORDER BY updated_at DESC LIMIT 1',
        { type: QueryTypes.SELECT }
      );
      if (!reports || reports.length === 0) {
        const [inserted] = await sequelize.query(
          "INSERT INTO sign_off_reports (deliverable_id, created_by, status, content, created_at, updated_at) VALUES ($1, $2, 'submitted', $3::jsonb, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days') RETURNING id, created_by, status, content, updated_at",
          { bind: ['D-TEST', null, JSON.stringify({ reportTitle: 'Test Report', reportContent: 'This is a test report for reminder simulation.' })] }
        );
        if (!inserted || inserted.length === 0) {
          console.log('Failed to create test report');
          process.exit(1);
        }
        reports = inserted;
        console.log(`Created test report with id: ${reports[0].id}`);
      }
    }

    const report = reports[0];
    const reviewers = await User.findAll({ where: { role: { [Op.in]: ['clientReviewer', 'ClientReviewer', 'clientreviewer'] }, is_active: true } });
    if (!reviewers || reviewers.length === 0) {
      console.log('No active client reviewers found');
      process.exit(0);
    }

    let content;
    try {
      content = typeof report.content === 'string' ? JSON.parse(report.content || '{}') : (report.content || {});
    } catch (_) {
      content = {};
    }
    const title = content.reportTitle || content.report_title || 'Sign-Off Report';

    const notifications = reviewers.map((client) => ({
      recipient_id: client.id,
      sender_id: report.created_by || null,
      type: 'approval',
      message: `Reminder: Please review and approve or request changes for "${title}"`,
      payload: {
        report_id: report.id,
        report_title: title,
        action_url: `/enhanced-client-review/${report.id}`,
      },
      is_read: false,
      created_at: new Date(),
    }));

    await Notification.bulkCreate(notifications);
    console.log(`Created notifications: ${notifications.length}`);
    process.exit(0);
  } catch (e) {
    console.error('Simulation error:', e);
    process.exit(1);
  }
}

run();