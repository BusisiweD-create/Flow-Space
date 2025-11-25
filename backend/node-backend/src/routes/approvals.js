const express = require('express');
const router = express.Router();
const { ApprovalRequest, Deliverable, User, Notification } = require('../models');
const { Op } = require('sequelize');

/**
 * @route GET /api/approvals
 * @desc Get all approval requests with optional filters
 * @access Private
 */
router.get('/', async (req, res) => {
  try {
    const { status, deliverable_id, requested_by, page = 1, limit = 100 } = req.query;
    
    const whereClause = {};
    if (status) whereClause.status = status;
    if (deliverable_id) whereClause.deliverable_id = deliverable_id;
    if (requested_by) whereClause.requested_by = requested_by;
    
    const offset = (parseInt(page) - 1) * parseInt(limit);
    
    const approvalRequests = await ApprovalRequest.findAll({
      where: whereClause,
      include: [
        {
          model: Deliverable,
          as: 'deliverable',
          attributes: ['id', 'title', 'description', 'status']
        },
        {
          model: User,
          as: 'requester',
          attributes: ['id', 'email', 'first_name', 'last_name']
        },
        {
          model: User,
          as: 'approver',
          attributes: ['id', 'email', 'first_name', 'last_name']
        }
      ],
      order: [['requested_at', 'DESC']],
      offset: offset,
      limit: parseInt(limit),
    });
    
    res.json(approvalRequests);
  } catch (error) {
    console.error('Error fetching approval requests:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/approvals/:id
 * @desc Get a specific approval request by ID
 * @access Private
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const approvalRequest = await ApprovalRequest.findByPk(id, {
      include: [
        {
          model: Deliverable,
          as: 'deliverable',
          attributes: ['id', 'title', 'description', 'status']
        },
        {
          model: User,
          as: 'requester',
          attributes: ['id', 'email', 'first_name', 'last_name']
        },
        {
          model: User,
          as: 'approver',
          attributes: ['id', 'email', 'first_name', 'last_name']
        }
      ]
    });
    
    if (!approvalRequest) {
      return res.status(404).json({ error: 'Approval request not found' });
    }
    
    res.json(approvalRequest);
  } catch (error) {
    console.error('Error fetching approval request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route POST /api/approvals
 * @desc Create a new approval request
 * @access Private
 */
router.post('/', async (req, res) => {
  try {
    const {
      deliverable_id,
      requested_by,
      due_date,
      comments,
      send_to
    } = req.body;
    
    // Validate required fields
    if (!deliverable_id || !requested_by) {
      return res.status(400).json({ error: 'Deliverable ID and requester ID are required' });
    }
    
    const approvalRequest = await ApprovalRequest.create({
      deliverable_id,
      requested_by,
      due_date: due_date ? new Date(due_date) : null,
      comments,
      status: 'pending'
    });
    
    // Fetch the created request with associations
    const createdRequest = await ApprovalRequest.findByPk(approvalRequest.id, {
      include: [
        {
          model: Deliverable,
          as: 'deliverable',
          attributes: ['id', 'title', 'description', 'status']
        },
        {
          model: User,
          as: 'requester',
          attributes: ['id', 'email', 'first_name', 'last_name']
        }
      ]
    });
    
    // Notify recipients (in-app and email)
    try {
      const EmailService = require('../services/emailService');
      const emailService = new EmailService();
      const deliverable = await Deliverable.findByPk(deliverable_id);
      const title = deliverable?.title || `Deliverable #${deliverable_id}`;
      const requester = await User.findByPk(requested_by);
      const requesterName = requester ? `${requester.first_name || ''} ${requester.last_name || ''}`.trim() : 'Delivery Lead';

      let roles = [];
      const target = (send_to || '').toLowerCase();
      if (target === 'system_admin') roles = ['system_admin'];
      else roles = ['client_reviewer'];

      const recipients = await User.findAll({ where: { role: { [Op.in]: roles } } });
      if (recipients && recipients.length > 0) {
        const notifications = recipients.map((recipient) => ({
          recipient_id: recipient.id,
          sender_id: requested_by,
          type: 'approval',
          message: `Approval request for ${title}`,
          payload: {
            approval_request_id: approvalRequest.id,
            deliverable_id,
            deliverable_title: title,
          },
          is_read: false,
          created_at: new Date(),
        }));
        await Notification.bulkCreate(notifications);

        // Send emails
        for (const recipient of recipients) {
          if (recipient.email) {
            await emailService.sendApprovalRequestEmail(
              recipient.email,
              `${recipient.first_name || ''} ${recipient.last_name || ''}`.trim(),
              title,
              requesterName
            );
          }
        }
      }
    } catch (notifyErr) {
      console.error('Error notifying recipients for approval request:', notifyErr);
    }

    res.status(201).json(createdRequest);
  } catch (error) {
    console.error('Error creating approval request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/approvals/:id/approve
 * @desc Approve an approval request
 * @access Private
 */
router.put('/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    const { approved_by, comments } = req.body;
    
    if (!approved_by) {
      return res.status(400).json({ error: 'Approver ID is required' });
    }
    
    const approvalRequest = await ApprovalRequest.findByPk(id);
    
    if (!approvalRequest) {
      return res.status(404).json({ error: 'Approval request not found' });
    }
    
    if (approvalRequest.status !== 'pending') {
      return res.status(400).json({ error: 'Approval request is not in pending status' });
    }
    
    await approvalRequest.update({
      status: 'approved',
      approved_by,
      approved_at: new Date(),
      comments: comments || approvalRequest.comments
    });
    
    // Update deliverable status to approved
    const deliverable = await Deliverable.findByPk(approvalRequest.deliverable_id);
    if (deliverable) {
      await deliverable.update({ status: 'approved' });
    }
    
    res.json(approvalRequest);
  } catch (error) {
    console.error('Error approving request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/approvals/:id/reject
 * @desc Reject an approval request
 * @access Private
 */
router.put('/:id/reject', async (req, res) => {
  try {
    const { id } = req.params;
    const { approved_by, comments } = req.body;
    
    if (!approved_by) {
      return res.status(400).json({ error: 'Approver ID is required' });
    }
    
    if (!comments) {
      return res.status(400).json({ error: 'Comments are required for rejection' });
    }
    
    const approvalRequest = await ApprovalRequest.findByPk(id);
    
    if (!approvalRequest) {
      return res.status(404).json({ error: 'Approval request not found' });
    }
    
    if (approvalRequest.status !== 'pending') {
      return res.status(400).json({ error: 'Approval request is not in pending status' });
    }
    
    await approvalRequest.update({
      status: 'rejected',
      approved_by,
      rejected_at: new Date(),
      comments
    });
    
    res.json(approvalRequest);
  } catch (error) {
    console.error('Error rejecting request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route PUT /api/approvals/:id/remind
 * @desc Send reminder for an approval request
 * @access Private
 */
router.put('/:id/remind', async (req, res) => {
  try {
    const { id } = req.params;
    const { report_id, send_to } = req.body || {};
    
    const approvalRequest = await ApprovalRequest.findByPk(id);
    
    if (!approvalRequest) {
      return res.status(404).json({ error: 'Approval request not found' });
    }
    
    if (approvalRequest.status !== 'pending') {
      return res.status(400).json({ error: 'Can only send reminders for pending requests' });
    }
    
    await approvalRequest.update({
      reminder_sent_at: new Date(),
      status: 'reminder_sent'
    });

    try {
      const EmailService = require('../services/emailService');
      const emailService = new EmailService();
      const deliverable = await Deliverable.findByPk(approvalRequest.deliverable_id);
      const title = deliverable?.title || `Deliverable #${approvalRequest.deliverable_id}`;

      const target = (send_to || '').toLowerCase();
      let roles = [];
      if (target === 'system_admin') roles = ['system_admin'];
      else roles = ['client_reviewer'];

      const recipients = await User.findAll({ where: { role: { [Op.in]: roles } } });

      const notifications = recipients.map((recipient) => ({
        recipient_id: recipient.id,
        sender_id: approvalRequest.requested_by,
        type: 'approval',
        message: `Reminder: Approval pending for ${title}`,
        payload: {
          approval_request_id: approvalRequest.id,
          deliverable_id: approvalRequest.deliverable_id,
          deliverable_title: title,
          ...(report_id ? { report_id } : {}),
        },
        is_read: false,
        created_at: new Date(),
      }));
      if (notifications.length > 0) {
        await Notification.bulkCreate(notifications);
        // Send emails
        const reportTitle = (() => {
          return null; // optional: could be fetched if needed
        })();
        for (const recipient of recipients) {
          if (recipient.email) {
            await emailService.sendApprovalReminderEmail(
              recipient.email,
              `${recipient.first_name || ''} ${recipient.last_name || ''}`.trim(),
              title,
              reportTitle
            );
          }
        }
      }
    } catch (notifyErr) {
      console.error('Error creating notifications/emails for reminder:', notifyErr);
    }

  res.json(approvalRequest);
  } catch (error) {
    console.error('Error sending reminder:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * @route GET /api/approvals/stats/metrics
 * @desc Get approval metrics for dashboard
 * @access Private
 */
router.get('/stats/metrics', async (req, res) => {
  try {
    const totalPending = await ApprovalRequest.count({
      where: { status: 'pending' }
    });
    
    const overdueApprovals = await ApprovalRequest.count({
      where: {
        status: 'pending',
        due_date: {
          [Op.lt]: new Date()
        }
      }
    });
    
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const approvalsNeedingReminder = await ApprovalRequest.count({
      where: {
        status: 'pending',
        due_date: {
          [Op.between]: [today, tomorrow]
        },
        reminder_sent_at: null
      }
    });
    
    res.json({
      pending_approvals_count: totalPending,
      overdue_approvals_count: overdueApprovals,
      approvals_needing_reminder_count: approvalsNeedingReminder
    });
  } catch (error) {
    console.error('Error fetching approval metrics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;