const express = require('express');
const router = express.Router();
const { Signoff, AuditLog } = require('../models');

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

/**
 * @route GET /api/signoff/:id
 * @desc Get a specific signoff by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
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
      return res.status(404).json({ error: 'No signoffs found for this entity' });
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