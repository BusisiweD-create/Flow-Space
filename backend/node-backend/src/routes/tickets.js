const express = require('express');
const router = express.Router();
const { Ticket } = require('../models');

// List tickets for a sprint
router.get('/sprint/:sprintId', async (req, res) => {
  try {
    const { sprintId } = req.params;
    const tickets = await Ticket.findAll({
      where: { sprint_id: parseInt(sprintId) },
      order: [['created_at', 'DESC']],
    });
    res.json({ success: true, data: tickets });
  } catch (error) {
    console.error('Error fetching sprint tickets:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create a ticket
router.post('/', async (req, res) => {
  try {
    const { sprintId, summary, description, assignee, priority, issue_type, type, status } = req.body || {};
    if (!sprintId || !summary || !description) {
      return res.status(400).json({ success: false, error: 'sprintId, summary, description are required' });
    }
    const now = new Date();
    const ticketId = `T-${Date.now()}`;
    const ticketKey = `SPR-${sprintId}-${Math.floor(Math.random() * 10000)}`;
    const ticket = await Ticket.create({
      ticket_id: ticketId,
      ticket_key: ticketKey,
      summary,
      description,
      status: status || 'To Do',
      issue_type: type || issue_type || 'task',
      priority: priority || 'medium',
      assignee: assignee || null,
      reporter: null,
      sprint_id: parseInt(sprintId),
      created_at: now,
      updated_at: now,
    });
    res.status(201).json({ success: true, data: ticket });
  } catch (error) {
    console.error('Error creating ticket:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Update ticket status
router.put('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body || {};
    const ticket = await Ticket.findByPk(parseInt(id));
    if (!ticket) {
      return res.status(404).json({ success: false, error: 'Ticket not found' });
    }
    await ticket.update({ status, updated_at: new Date() });
    res.json({ success: true, data: ticket });
  } catch (error) {
    console.error('Error updating ticket status:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

module.exports = router;