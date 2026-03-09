
const jwt = require('jsonwebtoken');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { User, Project } = require('../src/models');
const request = require('supertest');
const express = require('express');
const projectRoutes = require('../src/routes/projects');

const app = express();
app.use(express.json());

// We don't need to mock passport/user manually if we use a valid token,
// because authenticateToken middleware in projectRoutes will decode it.
app.use('/projects', projectRoutes);

async function testAdminProjects() {
  try {
    console.log('Testing GET /projects as systemAdmin...');
    
    // Generate a valid token
    const userPayload = {
      sub: '390dd57a-c40b-4050-b9a1-e8b0d6f69470', // Thabang's ID
      email: 'Thabang.Nkabinde@khonology.com',
      role: 'systemAdmin',
      type: 'access'
    };
    
    if (!process.env.JWT_SECRET) {
        console.error('JWT_SECRET not found in env');
        return;
    }

    const token = jwt.sign(userPayload, process.env.JWT_SECRET, { expiresIn: '1h' });

    const response = await request(app)
      .get('/projects')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    console.log('Response status:', response.status);
    
    let projects = [];
    if (Array.isArray(response.body)) {
      projects = response.body;
    } else if (response.body.data) {
      projects = response.body.data;
    } else if (response.body.projects) {
      projects = response.body.projects;
    }

    console.log(`Retrieved ${projects.length} projects.`);
    
    if (projects.length > 0) {
      console.log('First 3 projects:');
      projects.slice(0, 3).forEach(p => {
        console.log(`- ID: ${p.id}, Name: ${p.name}, Owner: ${p.owner ? (p.owner.first_name + ' ' + p.owner.last_name) : 'None'}`);
      });
    } else {
      console.log('No projects found. Debugging DB...');
      const dbProjects = await Project.count();
      console.log(`Total projects in DB: ${dbProjects}`);
    }

  } catch (error) {
    console.error('Error testing API:', error);
    if (error.response) {
        console.error('Response body:', error.response.body);
    }
  }
}

testAdminProjects();
