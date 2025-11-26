const express = require('express');
const router = express.Router();
const { Signoff, AuditLog, Deliverable, Sprint, User, sequelize } = require('../models');
const { QueryTypes } = require('sequelize');
function safeParseJson(text) {
  try { return JSON.parse(text); } catch (_) { return {}; }
}
let reportsTableReady = false;
async function ensureReportsTable() {
  if (reportsTableReady) return;
  try {
    console.log('[sign-off-reports] Ensuring table exists');
    await sequelize.query(
      "CREATE TABLE IF NOT EXISTS sign_off_reports (\n        id SERIAL PRIMARY KEY,\n        deliverable_id VARCHAR(255),\n        created_by VARCHAR(255),\n        status VARCHAR(50) DEFAULT 'draft',\n        content JSONB,\n        created_at TIMESTAMP DEFAULT NOW(),\n        updated_at TIMESTAMP DEFAULT NOW()\n      )"
    );
    console.log('[sign-off-reports] Table ensured');
    reportsTableReady = true;
  } catch (e) {
    console.error('Error ensuring sign_off_reports table:', e);
  }
}

/**
 * @route GET /api/signoff/sprint/:sprintId
 * @desc Get all signoffs for a specific sprint
 * @access Public
 */
router.get('/sprint/:sprintId', async (req, res) => {
  try {
    const { sprintId } = req.params;
    
    const signoffs = await Signoff.findAll({
      where: { 
        entity_type: 'sprint',
        entity_id: sprintId 
      },
      order: [['created_at', 'DESC']]
    });
    
    res.json(signoffs);
  } catch (error) {
    console.error('Error fetching sprint signoffs:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/', async (req, res) => {
  try {
    const base = req.baseUrl || '';
    if (!base.endsWith('/sign-off-reports')) {
      return res.status(404).json({ error: 'Endpoint not found' });
    }
    await ensureReportsTable();
    let results;
    try {
      results = await sequelize.query(
        "SELECT id, deliverable_id, created_by, status, content, created_at, updated_at FROM sign_off_reports ORDER BY created_at DESC",
        { type: QueryTypes.SELECT }
      );
    } catch (dbErr) {
      results = [];
    }
    const rawRows = Array.isArray(results) ? results : [];
    const userIds = [...new Set(rawRows.map(r => r.created_by).filter(Boolean))];
    const users = userIds.length > 0 ? await User.findAll({ where: { id: userIds } }) : [];
    const userMap = new Map(users.map(u => [u.id, `${u.first_name || ''} ${u.last_name || ''}`.trim()]));
    const reports = rawRows.map((row) => {
      try {
        const c = typeof row.content === 'string' ? safeParseJson(row.content) : (row.content || {});
        return {
          id: row.id,
          deliverableId: (row.deliverable_id || '').toString(),
          reportTitle: (c.reportTitle || c.report_title || 'Untitled Report'),
          reportContent: (c.reportContent || c.report_content || ''),
          sprintIds: c.sprintIds || c.sprint_ids || [],
          sprintPerformanceData: c.sprintPerformanceData || c.sprint_performance_data,
          knownLimitations: c.knownLimitations || c.known_limitations,
          nextSteps: c.nextSteps || c.next_steps,
          status: row.status || 'draft',
          createdAt: row.created_at,
          createdBy: (row.created_by || '').toString(),
          createdByName: userMap.get(row.created_by) || null,
          submittedAt: c.submittedAt || c.submitted_at,
          submittedBy: c.submittedBy || c.submitted_by,
          reviewedAt: c.reviewedAt || c.reviewed_at,
          reviewedBy: c.reviewedBy || c.reviewed_by,
          clientComment: c.clientComment || c.client_comment,
          changeRequestDetails: c.changeRequestDetails || c.change_request_details,
          approvedAt: c.approvedAt || c.approved_at,
          approvedBy: c.approvedBy || c.approved_by,
          digitalSignature: c.digitalSignature || c.digital_signature,
        };
      } catch (e) {
        return {
          id: row.id,
          deliverableId: (row.deliverable_id || '').toString(),
          reportTitle: 'Untitled Report',
          reportContent: '',
          sprintIds: [],
          status: row.status || 'draft',
          createdAt: row.created_at,
          createdBy: (row.created_by || '').toString(),
          createdByName: userMap.get(row.created_by) || null,
        };
      }
    });
    if (reports.length === 0) {
      try {
        const signoffs = await Signoff.findAll({
          where: { entity_type: 'deliverable' },
          include: [{ model: Deliverable, as: 'deliverable', attributes: ['id', 'title', 'created_by'] }],
          order: [['submitted_at', 'DESC']],
          limit: 50
        });
        const fallbackReports = signoffs.map((s) => ({
          id: s.id,
          deliverableId: (s.deliverable?.id || s.entity_id || '').toString(),
          reportTitle: s.deliverable?.title || 'Deliverable Sign-off',
          reportContent: s.comments || '',
          sprintIds: [],
          status: s.decision || 'pending',
          createdAt: s.submitted_at,
          createdBy: s.deliverable?.created_by || '',
          reviewedAt: s.reviewed_at,
          reviewedBy: null,
          clientComment: s.comments || null,
        }));
        return res.json(fallbackReports);
      } catch (e) {
        console.error('Error building fallback sign-off reports:', e);
      }
    }
    res.json(reports);
  } catch (error) {
    console.error('Error fetching sign-off-reports list:', error);
    return res.json([]);
  }
});

/**
 * @route GET /api/signoff/:id
 * @desc Get a specific signoff by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const base = req.baseUrl || '';
    if (base.endsWith('/sign-off-reports')) {
      await ensureReportsTable();
      const [results] = await sequelize.query(
        'SELECT id, deliverable_id, created_by, status, content, created_at, updated_at FROM sign_off_reports WHERE id = $1',
        { bind: [id] }
      );
      if (!results || results.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }
      const row = results[0];
      const c = typeof row.content === 'string' ? safeParseJson(row.content) : (row.content || {});
      const creator = row.created_by ? await User.findByPk(row.created_by) : null;
      const createdByName = creator ? `${creator.first_name} ${creator.last_name}` : null;
      const report = {
        id: row.id,
        deliverableId: (row.deliverable_id || '').toString(),
        reportTitle: (c.reportTitle || c.report_title || 'Untitled Report'),
        reportContent: (c.reportContent || c.report_content || ''),
        sprintIds: c.sprintIds || c.sprint_ids || [],
        sprintPerformanceData: c.sprintPerformanceData || c.sprint_performance_data,
        knownLimitations: c.knownLimitations || c.known_limitations,
        nextSteps: c.nextSteps || c.next_steps,
        status: row.status || 'draft',
        createdAt: row.created_at,
        createdBy: (row.created_by || '').toString(),
        createdByName: createdByName,
        submittedAt: c.submittedAt || c.submitted_at,
        submittedBy: c.submittedBy || c.submitted_by,
        reviewedAt: c.reviewedAt || c.reviewed_at,
        reviewedBy: c.reviewedBy || c.reviewed_by,
        clientComment: c.clientComment || c.client_comment,
        changeRequestDetails: c.changeRequestDetails || c.change_request_details,
        approvedAt: c.approvedAt || c.approved_at,
        approvedBy: c.approvedBy || c.approved_by,
        digitalSignature: c.digitalSignature || c.digital_signature,
      };
      return res.json(report);
    }
    const signoff = await Signoff.findByPk(id, {
      include: [
        { association: 'deliverable' },
        { association: 'sprint' },
        { association: 'audit_logs' }
      ]
    });
    if (!signoff) {
      return res.status(404).json({ error: 'Signoff not found' });
    }
    res.json(signoff);
  } catch (error) {
    console.error('Error fetching signoff:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route POST /api/signoff
 * @desc Create a new signoff
 * @access Private
 */
router.post('/', async (req, res) => {
  try {
    const base = req.baseUrl || '';
    if (base.endsWith('/sign-off-reports')) {
      await ensureReportsTable();
      const {
        deliverableId,
        reportTitle,
        reportContent,
        sprintIds,
        sprintPerformanceData,
        knownLimitations,
        nextSteps,
        status
      } = req.body || {};
      const content = {
        reportTitle,
        reportContent,
        sprintIds: sprintIds || [],
        sprintPerformanceData,
        knownLimitations,
        nextSteps,
        status: status || 'draft'
      };
      const [results] = await sequelize.query(
        'INSERT INTO sign_off_reports (deliverable_id, created_by, status, content) VALUES ($1, $2, $3, $4) RETURNING id, deliverable_id, created_by, status, content, created_at, updated_at',
        { bind: [deliverableId, (req.user && req.user.id) || null, status || 'draft', JSON.stringify(content)] }
      );
      const row = results[0];
      const c = typeof row.content === 'string' ? safeParseJson(row.content) : (row.content || {});
      const report = {
        id: row.id,
        deliverableId: (row.deliverable_id || '').toString(),
        reportTitle: (c.reportTitle || c.report_title || 'Untitled Report'),
        reportContent: (c.reportContent || c.report_content || ''),
        sprintIds: c.sprintIds || c.sprint_ids || [],
        sprintPerformanceData: c.sprintPerformanceData || c.sprint_performance_data,
        knownLimitations: c.knownLimitations || c.known_limitations,
        nextSteps: c.nextSteps || c.next_steps,
        status: row.status || 'draft',
        createdAt: row.created_at,
        createdBy: (row.created_by || '').toString()
      };
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('report_created', {
          id: report.id,
          deliverableId: report.deliverableId,
          reportTitle: report.reportTitle,
          created_by: report.createdBy
        });
      }
      return res.status(201).json(report);
    }
    const signoffData = req.body;
    const signoff = await Signoff.create(signoffData);
    res.status(201).json(signoff);
  } catch (error) {
    console.error('Error creating signoff:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/signoff/:id
 * @desc Update an existing signoff
 * @access Private
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const base = req.baseUrl || '';
    if (base.endsWith('/sign-off-reports')) {
      await ensureReportsTable();
      const updates = req.body || {};
      const [results] = await sequelize.query(
        'UPDATE sign_off_reports SET status = COALESCE(?, status), content = COALESCE(?::jsonb, content), updated_at = NOW() WHERE id = ? RETURNING id, deliverable_id, created_by, status, content, created_at, updated_at',
        { replacements: [updates.status ?? null, JSON.stringify(updates), id] }
      );
      if (!results || results.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }
      const row = results[0];
      const c = typeof row.content === 'string' ? safeParseJson(row.content) : (row.content || {});
      const report = {
        id: row.id,
        deliverableId: (row.deliverable_id || '').toString(),
        reportTitle: (c.reportTitle || c.report_title || 'Untitled Report'),
        reportContent: (c.reportContent || c.report_content || ''),
        sprintIds: c.sprintIds || c.sprint_ids || [],
        sprintPerformanceData: c.sprintPerformanceData || c.sprint_performance_data,
        knownLimitations: c.knownLimitations || c.known_limitations,
        nextSteps: c.nextSteps || c.next_steps,
        status: row.status || 'draft',
        createdAt: row.created_at,
        createdBy: (row.created_by || '').toString()
      };
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('report_updated', {
          id: report.id,
          deliverableId: report.deliverableId,
          reportTitle: report.reportTitle,
          created_by: report.createdBy,
          status: report.status
        });
      }
      return res.json(report);
    }
    const updateData = req.body;
    const signoff = await Signoff.findByPk(id);
    if (!signoff) {
      return res.status(404).json({ error: 'Signoff not found' });
    }
    await signoff.update(updateData);
    res.json(signoff);
  } catch (error) {
    console.error('Error updating signoff:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route DELETE /api/signoff/:id
 * @desc Delete a signoff
 * @access Private
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const base = req.baseUrl || '';
    if (base.endsWith('/sign-off-reports')) {
      await ensureReportsTable();
      const [rows] = await sequelize.query('DELETE FROM sign_off_reports WHERE id = $1 RETURNING id', { bind: [id] });
      if (!rows || rows.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('report_deleted', { id });
      }
      return res.status(204).send();
    }
    const signoff = await Signoff.findByPk(id);
    if (!signoff) {
      return res.status(404).json({ error: 'Signoff not found' });
    }
    await signoff.destroy();
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting signoff:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route POST /api/signoff/:id/approve
 * @desc Approve a signoff
 * @access Private
 */
router.post('/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    const base = req.baseUrl || '';
    if (base.endsWith('/sign-off-reports')) {
      await ensureReportsTable();
      const { comment, digitalSignature } = req.body || {};
      const [results] = await sequelize.query(
        "UPDATE sign_off_reports SET status = $2, content = COALESCE(content, '{}'::jsonb) || jsonb_build_object('approvedAt', NOW(), 'approvedBy', $3::text, 'clientComment', $4::text, 'digitalSignature', $5::text), updated_at = NOW() WHERE id = $1 RETURNING id, deliverable_id, created_by, status, content, created_at, updated_at",
        { bind: [id, 'approved', (req.user && req.user.id) || null, comment ?? null, digitalSignature ?? null] }
      );
      if (!results || results.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }
      const row = results[0];
      const c = typeof row.content === 'string' ? safeParseJson(row.content) : (row.content || {});
      const report = {
        id: row.id,
        deliverableId: (row.deliverable_id || '').toString(),
        reportTitle: (c.reportTitle || c.report_title || 'Untitled Report'),
        reportContent: (c.reportContent || c.report_content || ''),
        sprintIds: c.sprintIds || c.sprint_ids || [],
        status: row.status || 'approved',
        createdAt: row.created_at,
        createdBy: (row.created_by || '').toString(),
        approvedAt: c.approvedAt || c.approved_at,
        approvedBy: c.approvedBy || c.approved_by,
        clientComment: c.clientComment || c.client_comment,
        digitalSignature: c.digitalSignature || c.digital_signature
      };
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('report_approved', {
          id: report.id,
          deliverableId: report.deliverableId,
          reportTitle: report.reportTitle,
          created_by: report.createdBy,
          approvedBy: report.approvedBy
        });
      }
      return res.json(report);
    }
    const signoff = await Signoff.findByPk(id);
    if (!signoff) {
      return res.status(404).json({ error: 'Signoff not found' });
    }
    await signoff.update({ decision: 'approved' });
    res.json(signoff);
  } catch (error) {
    console.error('Error approving signoff:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:id/submit', async (req, res) => {
  try {
    const { id } = req.params;
    const base = req.baseUrl || '';
    if (base.endsWith('/sign-off-reports')) {
      await ensureReportsTable();
      const [results] = await sequelize.query(
        "UPDATE sign_off_reports SET status = $2, content = COALESCE(content, '{}'::jsonb) || jsonb_build_object('submittedAt', NOW()), updated_at = NOW() WHERE id = $1 RETURNING id, deliverable_id, created_by, status, content, created_at, updated_at",
        { bind: [id, 'submitted'] }
      );
      if (!results || results.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }
      const row = results[0];
      const c = typeof row.content === 'string' ? safeParseJson(row.content) : (row.content || {});
      const report = {
        id: row.id,
        deliverableId: (row.deliverable_id || '').toString(),
        reportTitle: (c.reportTitle || c.report_title || 'Untitled Report'),
        reportContent: (c.reportContent || c.report_content || ''),
        sprintIds: c.sprintIds || c.sprint_ids || [],
        sprintPerformanceData: c.sprintPerformanceData || c.sprint_performance_data,
        knownLimitations: c.knownLimitations || c.known_limitations,
        nextSteps: c.nextSteps || c.next_steps,
        status: row.status || 'submitted',
        createdAt: row.created_at,
        createdBy: (row.created_by || '').toString(),
        submittedAt: c.submittedAt || c.submitted_at,
        submittedBy: c.submittedBy || c.submitted_by
      };
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('report_submitted', {
          id: report.id,
          deliverableId: report.deliverableId,
          reportTitle: report.reportTitle,
          created_by: report.createdBy
        });
      }
      return res.json(report);
    }
    return res.status(404).json({ error: 'Endpoint not found' });
  } catch (error) {
    console.error('Error submitting sign-off report:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:id/signatures', async (req, res) => {
  try {
    const { id } = req.params;
    const base = req.baseUrl || '';
    if (base.endsWith('/sign-off-reports')) {
      await ensureReportsTable();
      const [results] = await sequelize.query(
        'SELECT id, content, updated_at FROM sign_off_reports WHERE id = $1',
        { bind: [id] }
      );
      if (!results || results.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }
      const row = results[0];
      const c = typeof row.content === 'string' ? safeParseJson(row.content) : (row.content || {});
      const sigs = [];
      const arr = Array.isArray(c.signatures) ? c.signatures : [];
      for (const s of arr) {
        sigs.push({
          signature_data: s.signature_data || s.digitalSignature || s.digital_signature || null,
          signer_name: s.signer_name || null,
          signer_role: s.signer_role || null,
          signed_at: s.signed_at || row.updated_at,
          is_valid: s.is_valid !== undefined ? s.is_valid : true,
          signature_type: s.signature_type || 'manual'
        });
      }
      if (sigs.length === 0 && (c.digitalSignature || c.digital_signature)) {
        sigs.push({
          signature_data: c.digitalSignature || c.digital_signature,
          signer_name: null,
          signer_role: null,
          signed_at: c.approvedAt || c.approved_at || row.updated_at,
          is_valid: true,
          signature_type: 'manual'
        });
      }
      return res.json({ success: true, data: sigs });
    }
    return res.status(404).json({ error: 'Endpoint not found' });
  } catch (error) {
    console.error('Error fetching report signatures:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:id/request-changes', async (req, res) => {
  try {
    const { id } = req.params;
    const base = req.baseUrl || '';
    if (base.endsWith('/sign-off-reports')) {
      const { changeRequestDetails } = req.body || {};
      await ensureReportsTable();
      const [existing] = await sequelize.query(
        "SELECT id, deliverable_id, created_by, status, content, created_at, updated_at FROM sign_off_reports WHERE id = $1",
        { bind: [id] }
      );
      if (!existing || existing.length === 0) {
        return res.status(404).json({ error: 'Report not found' });
      }
      const cur = existing[0];
      const curC = typeof cur.content === 'string' ? safeParseJson(cur.content) : (cur.content || {});
      const merged = {
        ...curC,
        changeRequestDetails: changeRequestDetails ?? curC.changeRequestDetails ?? curC.change_request_details ?? null,
        reviewedAt: new Date().toISOString(),
        reviewedBy: (req.user && req.user.id) ? String(req.user.id) : (curC.reviewedBy || null)
      };
      const [results] = await sequelize.query(
        "UPDATE sign_off_reports SET status = $2, content = $3::jsonb, updated_at = NOW() WHERE id = $1 RETURNING id, deliverable_id, created_by, status, content, created_at, updated_at",
        { bind: [id, 'change_requested', JSON.stringify(merged)] }
      );
      const row = results[0];
      const c = typeof row.content === 'string' ? safeParseJson(row.content) : (row.content || {});
      const report = {
        id: row.id,
        deliverableId: (row.deliverable_id || '').toString(),
        reportTitle: (c.reportTitle || c.report_title || 'Untitled Report'),
        reportContent: (c.reportContent || c.report_content || ''),
        sprintIds: c.sprintIds || c.sprint_ids || [],
        status: row.status || 'change_requested',
        createdAt: row.created_at,
        createdBy: (row.created_by || '').toString(),
        changeRequestDetails: c.changeRequestDetails || c.change_request_details
      };
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('report_change_requested', {
          id: report.id,
          deliverableId: report.deliverableId,
          reportTitle: report.reportTitle,
          created_by: report.createdBy,
          changeRequestDetails: report.changeRequestDetails
        });
      }
      return res.json(report);
    }
    return res.status(404).json({ error: 'Endpoint not found' });
  } catch (error) {
    console.error('Error requesting changes:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/signoff/:entity_type/:entity_id/report
 * @desc Generate a signoff report for a specific entity
 * @access Public
 */
router.get('/:entity_type/:entity_id/report', async (req, res) => {
  try {
    const { entity_type, entity_id } = req.params;
    const { format = 'json' } = req.query;
    
    // Validate entity type
    if (!['sprint', 'deliverable'].includes(entity_type)) {
      return res.status(400).json({ error: 'Invalid entity type. Must be sprint or deliverable' });
    }
    
    // Validate entity ID
    const entityId = parseInt(entity_id);
    if (isNaN(entityId)) {
      return res.status(400).json({ error: 'Invalid entity ID. Must be a number' });
    }
    
    // Get all signoffs for the entity
    const signoffs = await Signoff.findAll({
      where: { 
        entity_type: entity_type,
        entity_id: entityId 
      },
      order: [['submitted_at', 'DESC']]
    });
    
    if (signoffs.length === 0) {
      const baseInfo = entity_type === 'deliverable'
        ? await Deliverable.findByPk(entityId)
        : await Sprint.findByPk(entityId);
      const reportData = {
        metadata: {
          entity_type,
          entity_id: entityId,
          format,
          generated_at: new Date().toISOString(),
          name: baseInfo?.title || baseInfo?.name || undefined,
          status: baseInfo?.status || undefined
        },
        statistics: {
          total_signoffs: 0,
          approved_count: 0,
          rejected_count: 0,
          pending_count: 0,
          change_requested_count: 0,
          completion_rate: 0
        },
        signoffs: []
      };
      switch (format) {
        case 'json':
          return res.json(reportData);
        case 'text':
          return res.type('text/plain').send(JSON.stringify(reportData, null, 2));
        case 'html':
        case 'pdf':
          return res.type('text/html').send(`<h1>Sign-off Report for ${entity_type} ${entityId}</h1><pre>${JSON.stringify(reportData, null, 2)}</pre>`);
        default:
          return res.status(400).json({ error: 'Invalid format. Must be json, text, html, or pdf' });
      }
    }
    
    // Calculate statistics
    const totalSignoffs = signoffs.length;
    const approvedCount = signoffs.filter(s => s.decision === 'approved').length;
    const rejectedCount = signoffs.filter(s => s.decision === 'rejected').length;
    const pendingCount = signoffs.filter(s => s.decision === 'pending').length;
    const changeRequestedCount = signoffs.filter(s => s.decision === 'change_requested').length;
    const completionRate = totalSignoffs > 0 
      ? Math.round(((approvedCount + rejectedCount + changeRequestedCount) / totalSignoffs) * 100) 
      : 0;
    
    // Prepare report data
    const reportData = {
      metadata: {
        entity_type: entity_type,
        entity_id: entityId,
        format: format,
        generated_at: new Date().toISOString()
      },
      statistics: {
        total_signoffs: totalSignoffs,
        approved_count: approvedCount,
        rejected_count: rejectedCount,
        pending_count: pendingCount,
        change_requested_count: changeRequestedCount,
        completion_rate: completionRate
      },
      signoffs: signoffs.map(s => ({
        id: s.id,
        signer_name: s.signer_name,
        signer_email: s.signer_email,
        signer_role: s.signer_role,
        signer_company: s.signer_company,
        decision: s.decision,
        comments: s.comments,
        change_request_details: s.change_request_details,
        submitted_at: s.submitted_at,
        reviewed_at: s.reviewed_at,
        responded_at: s.responded_at
      }))
    };
    
    // Generate content based on format
    switch (format) {
      case 'json':
        res.json(reportData);
        break;
      case 'text':
        res.type('text/plain').send(JSON.stringify(reportData, null, 2));
        break;
      case 'html':
      case 'pdf':
        res.type('text/html').send(`<h1>Sign-off Report for ${entity_type} ${entityId}</h1><pre>${JSON.stringify(reportData, null, 2)}</pre>`);
        break;
      default:
        res.status(400).json({ error: 'Invalid format. Must be json, text, html, or pdf' });
    }
    
  } catch (error) {
    console.error('Error generating signoff report:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
