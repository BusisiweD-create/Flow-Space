const { Project, User } = require('../src/models');

async function listProjects() {
  try {
    const projects = await Project.findAll({
      include: [{
        model: User,
        as: 'owner',
        attributes: ['id', 'email', 'first_name', 'last_name']
      }]
    });
    
    console.log('Total Projects found:', projects.length);
    projects.forEach(p => {
      const ownerName = p.owner ? `${p.owner.first_name} ${p.owner.last_name} (${p.owner.email})` : 'NO OWNER';
      console.log(`[${p.id}] ${p.name} - Key: ${p.key} - Owner: ${ownerName}`);
    });
  } catch (error) {
    console.error('Error:', error);
  }
}

listProjects();
