const express = require('express');
const router = express.Router();
const { ApprovalRequest, Deliverable, User, Notification, sequelize } = require('../models');
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
      if (target === 'system_admin') roles = ['system_admin','systemAdmin','SystemAdmin'];
      else if (target === 'delivery_lead') roles = ['delivery_lead','deliveryLead','DeliveryLead'];
      else roles = ['client_reviewer','clientReviewer','ClientReviewer','delivery_lead','deliveryLead','DeliveryLead'];

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
    let { approved_by, comments } = req.body || {};
    if ((!approved_by || String(approved_by).trim() === '') && req.user && req.user.id) {
      approved_by = req.user.id;
    }
    
    if (!approved_by) {
      return res.status(400).json({ error: 'Approver ID is required' });
    }
    if (typeof id === 'string' && id.startsWith('report:')) {
      const rid = parseInt(id.split(':')[1]);
      if (!Number.isFinite(rid)) {
        return res.status(400).json({ error: 'Invalid report ID' });
      }
      try {
        await sequelize.query(
          "CREATE TABLE IF NOT EXISTS sign_off_reports (\n        id SERIAL PRIMARY KEY,\n        deliverable_id VARCHAR(255),\n        created_by VARCHAR(255),\n        status VARCHAR(50) DEFAULT 'draft',\n        content JSONB,\n        created_at TIMESTAMP DEFAULT NOW(),\n        updated_at TIMESTAMP DEFAULT NOW()\n      )"
        );
      } catch (_) {}
      const [rows] = await sequelize.query(
        'SELECT id, deliverable_id, created_by, status, content FROM sign_off_reports WHERE id = $1',
        { bind: [rid] }
      );
      const row = rows && rows[0];
      if (!row) {
        return res.status(404).json({ error: 'Report not found' });
      }
      if (String(row.status) === 'approved') {
        return res.json({ success: true, data: { report_id: rid, status: 'approved' } });
      }
      const t = await sequelize.transaction();
      try {
        await sequelize.query(
          "UPDATE sign_off_reports SET status = 'approved', updated_at = NOW() WHERE id = $1",
          { bind: [rid], transaction: t }
        );
        const did = parseInt(row.deliverable_id);
        if (Number.isFinite(did)) {
          const deliverable = await Deliverable.findByPk(did, { transaction: t });
          if (deliverable) {
            await deliverable.update({ status: 'approved' }, { transaction: t });
          }
          await ApprovalRequest.update(
            {
              status: 'approved',
              approved_by,
              approved_at: new Date(),
              comments: comments ?? null
            },
            { where: { deliverable_id: did, status: { [Op.in]: ['pending','reminder_sent'] } }, transaction: t }
          );
        }
        await t.commit();
      } catch (err) {
        await t.rollback();
        console.error('Report approval transaction failed:', err);
        return res.status(500).json({ error: 'Failed to approve report' });
      }
      try {
        const rec = row.created_by && /^[0-9a-fA-F-]{36}$/.test(String(row.created_by)) ? String(row.created_by) : null;
        const snd = approved_by && /^[0-9a-fA-F-]{36}$/.test(String(approved_by)) ? String(approved_by) : null;
        if (rec) {
          await Notification.create({
            recipient_id: rec,
            sender_id: snd,
            type: 'approval',
            message: `Report approved`,
            payload: { report_id: rid, deliverable_id: row.deliverable_id },
            is_read: false,
            created_at: new Date()
          });
        }
      } catch (_) {}
      return res.json({ success: true, data: { report_id: rid, status: 'approved' } });
    }
    
    const approvalRequest = await ApprovalRequest.findByPk(id);
    
    if (!approvalRequest) {
      return res.status(404).json({ error: 'Approval request not found' });
    }
    
    if (!['pending','reminder_sent'].includes(String(approvalRequest.status))) {
      return res.status(409).json({ error: 'Approval request is not in approvable status' });
    }
    
    const t = await sequelize.transaction();
    try {
      await approvalRequest.update({
        status: 'approved',
        approved_by,
        approved_at: new Date(),
        comments: comments || approvalRequest.comments
      }, { transaction: t });
      const did = parseInt(approvalRequest.deliverable_id);
      if (Number.isFinite(did)) {
        const deliverable = await Deliverable.findByPk(did, { transaction: t });
        if (deliverable) {
          await deliverable.update({ status: 'approved' }, { transaction: t });
        }
      }
      await t.commit();
    } catch (err) {
      await t.rollback();
      console.error('Approval transaction failed:', err);
      return res.status(500).json({ error: 'Failed to approve request' });
    }
    
    try {
      const rec = approvalRequest.requested_by && /^[0-9a-fA-F-]{36}$/.test(String(approvalRequest.requested_by)) ? String(approvalRequest.requested_by) : null;
      const snd = approved_by && /^[0-9a-fA-F-]{36}$/.test(String(approved_by)) ? String(approved_by) : null;
      if (rec) {
        await Notification.create({
          recipient_id: rec,
          sender_id: snd,
          type: 'approval',
          message: `Approval granted for deliverable #${approvalRequest.deliverable_id}`,
          payload: { approval_request_id: approvalRequest.id, deliverable_id: approvalRequest.deliverable_id },
          is_read: false,
          created_at: new Date()
        });
      }
    } catch (_) {}
    
    res.json({ success: true, data: approvalRequest });
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
    let { approved_by, comments } = req.body || {};
    if ((!approved_by || String(approved_by).trim() === '') && req.user && req.user.id) {
      approved_by = req.user.id;
    }
    
    if (!approved_by) {
      return res.status(400).json({ error: 'Approver ID is required' });
    }
    
    comments = comments || 'Changes requested';
    
    const approvalRequest = await ApprovalRequest.findByPk(id);
    
    if (!approvalRequest) {
      return res.status(404).json({ error: 'Approval request not found' });
    }
    
    if (!['pending','reminder_sent'].includes(String(approvalRequest.status))) {
      return res.status(409).json({ error: 'Approval request is not in rejectable status' });
    }
    
    const t = await sequelize.transaction();
    try {
      await approvalRequest.update({
        status: 'rejected',
        approved_by,
        rejected_at: new Date(),
        comments
      }, { transaction: t });
      const did = parseInt(approvalRequest.deliverable_id);
      if (Number.isFinite(did)) {
        const deliverable = await Deliverable.findByPk(did, { transaction: t });
        if (deliverable) {
          await deliverable.update({ status: 'change_requested' }, { transaction: t });
        }
      }
      await t.commit();
    } catch (err) {
      await t.rollback();
      console.error('Reject transaction failed:', err);
      return res.status(500).json({ error: 'Failed to reject request' });
    }
    try {
      await Notification.create({
        recipient_id: approvalRequest.requested_by,
        sender_id: approved_by,
        type: 'approval',
        message: `Approval rejected for deliverable #${approvalRequest.deliverable_id}`,
        payload: { approval_request_id: approvalRequest.id, deliverable_id: approvalRequest.deliverable_id },
        is_read: false,
        created_at: new Date()
      });
    } catch (_) {}
    
    res.json({ success: true, data: approvalRequest });
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
      if (target === 'system_admin') roles = ['system_admin','systemAdmin','SystemAdmin'];
      else if (target === 'delivery_lead') roles = ['delivery_lead','deliveryLead','DeliveryLead'];
      else roles = ['client_reviewer','clientReviewer','ClientReviewer','delivery_lead','deliveryLead','DeliveryLead'];

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
    // Align dashboard pending count with reports pending approval
    // Count sign_off_reports where status indicates awaiting client approval
    let totalPending = 0;
    try {
      const [rows] = await sequelize.query(
        "SELECT COUNT(*)::int AS cnt FROM sign_off_reports WHERE status IN ('submitted','under_review')"
      );
      totalPending = (rows && rows[0] && rows[0].cnt) || 0;
    } catch (_) {
      totalPending = await ApprovalRequest.count({ where: { status: 'pending' } });
    }
    
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
