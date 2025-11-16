const express = require('express');
const router = express.Router();
const { Project } = require('../models');
const { authenticateToken } = require('../middleware/auth');

/**
 * @route GET /api/projects
 * @desc Get all projects with pagination
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const projects = await Project.findAll({
      offset: parseInt(skip),
      limit: parseInt(limit),
      order: [['created_at', 'DESC']]
    });
    
    res.json({
      success: true,
      data: projects
    });
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route GET /api/projects/:id
 * @desc Get a specific project by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const project = await Project.findByPk(id);
    
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }
    
    res.json({
      success: true,
      data: project
    });
  } catch (error) {
    console.error('Error fetching project:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route POST /api/projects
 * @desc Create a new project
 * @access Private
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    // Generate a project key from the name (convert to uppercase, replace spaces with underscores)
    const projectKey = req.body.name
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, '_')
      .substring(0, 20);
    
    const projectData = {
      ...req.body,
      key: projectKey,
      created_by: req.user.id
    };
    
    console.log('Creating project with data:', projectData);
    
    const project = await Project.create(projectData);
    
    res.status(201).json({
      success: true,
      data: project
    });
  } catch (error) {
    console.error('Error creating project:', error);
    console.error('Error details:', error.message);
    console.error('Error stack:', error.stack);
    
    // Provide more detailed error information
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      message: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

/**
 * @route PUT /api/projects/:id
 * @desc Update an existing project
 * @access Private
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const project = await Project.findByPk(id);
    
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }
    
    await project.update(updateData);
    
    res.json({
      success: true,
      data: project
    });
  } catch (error) {
    console.error('Error updating project:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route DELETE /api/projects/:id
 * @desc Delete a project
 * @access Private
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const project = await Project.findByPk(id);
    
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }
    
    await project.destroy();
    
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting project:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

module.exports = router;