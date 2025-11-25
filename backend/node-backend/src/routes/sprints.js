const express = require('express');
const router = express.Router();
const { Sprint, Project } = require('../models');

function normalizeSprintData(body) {
  const d = {};
  if (body.name != null) d.name = body.name;
  if (body.description != null) d.description = body.description;
  const sd = body.start_date ?? body.startDate;
  if (sd != null) d.start_date = sd;
  const ed = body.end_date ?? body.endDate;
  if (ed != null) d.end_date = ed;
  const pid = body.project_id ?? body.projectId;
  if (pid != null) d.project_id = pid;
  const planned = body.planned_points ?? body.plannedPoints;
  if (planned != null) d.planned_points = planned;
  const committed = body.committed_points ?? body.committedPoints;
  if (committed != null) d.committed_points = committed;
  const completed = body.completed_points ?? body.completedPoints;
  if (completed != null) d.completed_points = completed;
  const carried = body.carried_over_points ?? body.carriedOverPoints;
  if (carried != null) d.carried_over_points = carried;
  const added = body.added_during_sprint ?? body.addedDuringSprint;
  if (added != null) d.added_during_sprint = added;
  const removed = body.removed_during_sprint ?? body.removedDuringSprint;
  if (removed != null) d.removed_during_sprint = removed;
  const tpr = body.test_pass_rate ?? body.testPassRate;
  if (tpr != null) d.test_pass_rate = tpr;
  const cov = body.code_coverage ?? body.codeCoverage;
  if (cov != null) d.code_coverage = cov;
  const esc = body.escaped_defects ?? body.escapedDefects;
  if (esc != null) d.escaped_defects = esc;
  const opened = body.defects_opened ?? body.defectsOpened;
  if (opened != null) d.defects_opened = opened;
  const closed = body.defects_closed ?? body.defectsClosed;
  if (closed != null) d.defects_closed = closed;
  const mix = body.defect_severity_mix ?? body.defectSeverityMix;
  if (mix != null) d.defect_severity_mix = mix;
  const cr = body.code_review_completion ?? body.codeReviewCompletion;
  if (cr != null) d.code_review_completion = cr;
  const doc = body.documentation_status ?? body.documentationStatus;
  if (doc != null) d.documentation_status = doc;
  const uatNotes = body.uat_notes ?? body.uatNotes;
  if (uatNotes != null) d.uat_notes = uatNotes;
  const uatRate = body.uat_pass_rate ?? body.uatPassRate;
  if (uatRate != null) d.uat_pass_rate = uatRate;
  const risksIdentified = body.risks_identified ?? body.risksIdentified;
  if (risksIdentified != null) d.risks_identified = risksIdentified;
  const risksMitigated = body.risks_mitigated ?? body.risksMitigated;
  if (risksMitigated != null) d.risks_mitigated = risksMitigated;
  const blockers = body.blockers;
  if (blockers != null) d.blockers = blockers;
  const decisions = body.decisions;
  if (decisions != null) d.decisions = decisions;
  const status = body.status ?? body.state;
  if (status != null) d.status = status;
  const createdBy = body.created_by ?? body.createdBy;
  if (createdBy != null) d.created_by = createdBy;
  return d;
}

/**
 * @route GET /api/sprints
 * @desc Get all sprints with pagination
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const sprints = await Sprint.findAll({
      offset: parseInt(skip),
      limit: parseInt(limit),
      order: [['created_at', 'DESC']],
      include: [{ model: Project, as: 'project', attributes: ['id', 'name', 'key'] }]
    });
    
    res.json({
      success: true,
      data: sprints
    });
  } catch (error) {
    console.error('Error fetching sprints:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route GET /api/sprints/:id
 * @desc Get a specific sprint by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const sprint = await Sprint.findByPk(id, {
      include: [
        { association: 'deliverables' },
        { association: 'signoffs' },
        { association: 'audit_logs' },
        { model: Project, as: 'project', attributes: ['id', 'name', 'key'] }
      ]
    });
    
    if (!sprint) {
      return res.status(404).json({ 
        success: false,
        error: 'Sprint not found' 
      });
    }
    
    res.json({
      success: true,
      data: sprint
    });
  } catch (error) {
    console.error('Error fetching sprint:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route POST /api/sprints
 * @desc Create a new sprint
 * @access Private
 */
router.post('/', async (req, res) => {
  try {
    const sprintData = normalizeSprintData(req.body);
    const sprint = await Sprint.create(sprintData);
    
    res.status(201).json({
      success: true,
      data: sprint
    });
  } catch (error) {
    console.error('Error creating sprint:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route PUT /api/sprints/:id
 * @desc Update an existing sprint
 * @access Private
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = normalizeSprintData(req.body);
    
    const sprint = await Sprint.findByPk(id);
    
    if (!sprint) {
      return res.status(404).json({ error: 'Sprint not found' });
    }
    
    await sprint.update(updateData);
    
    res.json({ success: true, data: sprint });
  } catch (error) {
    console.error('Error updating sprint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route DELETE /api/sprints/:id
 * @desc Delete a sprint
 * @access Private
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const sprint = await Sprint.findByPk(id);
    
    if (!sprint) {
      return res.status(404).json({ error: 'Sprint not found' });
    }
    
    await sprint.destroy();
    
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting sprint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;