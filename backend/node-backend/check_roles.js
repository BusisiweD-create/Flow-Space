
const { User, Project, sequelize } = require('./src/models');

async function checkRoles() {
  try {
    // Wait for connection to be established (although require should handle it)
    await sequelize.authenticate();
    console.log('Connection has been established successfully.');

    const users = await User.findAll({
        attributes: ['id', 'email', 'role']
    });
    console.log('Users and roles:');
    users.forEach(u => {
      console.log(`User: ${u.email}, Role: '${u.role}'`);
    });

    const projects = await Project.findAll();
    console.log(`\nTotal projects: ${projects.length}`);
    projects.forEach(p => {
        console.log(`Project: ${p.name}, Owner: ${p.owner_id}, CreatedBy: ${p.created_by}`);
    });

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await sequelize.close();
  }
}

checkRoles();
