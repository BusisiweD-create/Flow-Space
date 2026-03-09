const { User } = require('../src/models');

async function listUsers() {
  try {
    const users = await User.findAll({
      attributes: ['id', 'email', 'role', 'first_name', 'last_name']
    });
    
    console.log('Users found:', users.length);
    users.forEach(u => {
      console.log(`- ${u.email} (${u.role})`);
    });
  } catch (error) {
    console.error('Error:', error);
  }
}

listUsers();
