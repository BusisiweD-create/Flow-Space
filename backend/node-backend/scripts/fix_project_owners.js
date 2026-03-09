const { sequelize, User, Project, ProjectMember } = require('../src/models');
const { Op } = require('sequelize');

async function fixProjectOwners() {
  try {
    // Connect to database
    await sequelize.authenticate();
    console.log('Database connected');

    // 1. Find the System Admin user
    const adminEmail = 'Thabang.Nkabinde@khonology.com';
    const admin = await User.findOne({ where: { email: adminEmail } });

    if (!admin) {
      console.error(`Admin user ${adminEmail} not found`);
      process.exit(1);
    }

    console.log(`Found admin: ${admin.first_name} ${admin.last_name} (${admin.id})`);

    // 2. Find projects with no owner
    const projects = await Project.findAll({
      where: {
        owner_id: null
      }
    });

    console.log(`Found ${projects.length} projects with no owner`);

    if (projects.length === 0) {
      console.log('No projects to fix');
      process.exit(0);
    }

    // 3. Update each project
    for (const project of projects) {
      console.log(`Fixing project: ${project.name} (${project.id})`);
      
      // Assign owner
      project.owner_id = admin.id;
      await project.save();

      // Ensure admin is a member of the project
      const existingMember = await ProjectMember.findOne({
        where: {
          project_id: project.id,
          user_id: admin.id
        }
      });

      if (!existingMember) {
        await ProjectMember.create({
          project_id: project.id,
          user_id: admin.id,
          role: 'owner'
        });
        console.log('  Added admin as project member (owner)');
      } else {
        if (existingMember.role !== 'owner') {
          existingMember.role = 'owner';
          await existingMember.save();
          console.log('  Updated member role to owner');
        } else {
          console.log('  Admin is already an owner member');
        }
      }
    }

    console.log('Done!');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

fixProjectOwners();
