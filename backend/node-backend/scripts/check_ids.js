const { Project, User } = require('../src/models');

async function checkIds() {
  try {
    const user = await User.findOne({ where: { email: 'Thabang.Nkabinde@khonology.com' } });
    if (!user) {
      console.log('User not found!');
      return;
    }
    console.log(`User ID: ${user.id}`);

    const projects = await Project.findAll({ where: { owner_id: user.id } });
    console.log(`Projects owned by this user ID: ${projects.length}`);
    
    const allProjects = await Project.findAll();
    console.log(`Total projects in DB: ${allProjects.length}`);
    
    if (projects.length !== allProjects.length) {
       console.log('Some projects have different owners:');
       allProjects.forEach(p => {
         if (p.owner_id !== user.id) {
           console.log(`- ${p.name}: Owner ID ${p.owner_id}`);
         }
       });
    }

  } catch (error) {
    console.error('Error:', error);
  }
}

checkIds();
