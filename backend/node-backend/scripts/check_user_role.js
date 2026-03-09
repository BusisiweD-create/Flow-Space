
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { User } = require('../src/models');

async function checkUserRole() {
  try {
    const user = await User.findOne({ where: { email: 'Thabang.Nkabinde@khonology.com' } });
    if (!user) {
      console.log('User not found!');
      return;
    }
    console.log(`User ID: ${user.id}`);
    console.log(`User Email: ${user.email}`);
    console.log(`User Role: '${user.role}'`); // Quote it to see spaces
  } catch (error) {
    console.error('Error:', error);
  }
}

checkUserRole();
