const { Project, User } = require('../src/models');
const { Op } = require('sequelize');

async function checkProjects() {
  try {
    const projects = await Project.findAll();
    console.log(`Total projects: ${projects.length}`);
    for (const p of projects) {
      console.log(`Project: ${p.name} (ID: ${p.id}), Owner ID: ${p.owner_id}, Created By: ${p.created_by}`);
    }
  } catch (error) {
    console.error(error);
  }
}

checkProjects();
