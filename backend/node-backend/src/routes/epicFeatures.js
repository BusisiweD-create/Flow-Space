const express = require('express');
const router = express.Router();
const { EpicFeature, EpicFeatureSprint, Sprint } = require('../models');

router.get('/', async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const items = await EpicFeature.findAll({
      offset: parseInt(skip),
      limit: parseInt(limit),
      order: [['created_at', 'DESC']]
    });
    res.json({ success: true, data: items });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const item = await EpicFeature.findByPk(id, {
      include: [
        { association: 'linked_sprints' },
        { association: 'audit_logs' }
      ]
    });
    if (!item) return res.status(404).json({ error: 'Epic/Feature not found' });
    res.json({ success: true, data: item });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/', async (req, res) => {
  try {
    const { sprintIds, ...data } = req.body || {};
    const created = await EpicFeature.create(data);
    if (Array.isArray(sprintIds) && sprintIds.length > 0) {
      const ids = sprintIds.map((id) => parseInt(id)).filter((n) => Number.isFinite(n));
      await Promise.all(ids.map((sprintId) => EpicFeatureSprint.create({ epic_feature_id: created.id, sprint_id: sprintId })));
    }
    res.status(201).json({ success: true, data: created });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body || {};
    const item = await EpicFeature.findByPk(id);
    if (!item) return res.status(404).json({ error: 'Epic/Feature not found' });
    await item.update(updates);
    res.json({ success: true, data: item });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const item = await EpicFeature.findByPk(id);
    if (!item) return res.status(404).json({ error: 'Epic/Feature not found' });
    await item.destroy();
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:id/link-sprints', async (req, res) => {
  try {
    const { id } = req.params;
    const { sprintIds } = req.body || {};
    const item = await EpicFeature.findByPk(id);
    if (!item) return res.status(404).json({ error: 'Epic/Feature not found' });
    if (!Array.isArray(sprintIds) || sprintIds.length === 0) return res.status(400).json({ error: 'sprintIds required' });
    const ids = sprintIds.map((sid) => parseInt(sid)).filter((n) => Number.isFinite(n));
    const existing = await EpicFeatureSprint.findAll({ where: { epic_feature_id: id } });
    const existingIds = new Set(existing.map((e) => e.sprint_id));
    const toCreate = ids.filter((sid) => !existingIds.has(sid));
    await Promise.all(toCreate.map((sid) => EpicFeatureSprint.create({ epic_feature_id: id, sprint_id: sid })));
    const linked = await Sprint.findAll({ include: [{ association: 'epic_features', where: { id } }] });
    res.json({ success: true, data: linked });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:id/unlink-sprint/:sprintId', async (req, res) => {
  try {
    const { id, sprintId } = req.params;
    await EpicFeatureSprint.destroy({ where: { epic_feature_id: parseInt(id), sprint_id: parseInt(sprintId) } });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
