const database = require('../config/database');
const { DataTypes } = require('sequelize');

// Import all models
const Deliverable = require('./Deliverable');
const Sprint = require('./Sprint');
const DeliverableSprint = require('./DeliverableSprint');
const Signoff = require('./Signoff');
const AuditLog = require('./AuditLog');
const User = require('./User');
const UserProfile = require('./UserProfile');
const RefreshToken = require('./RefreshToken');
const UserSettings = require('./UserSettings');
const Notification = require('./Notification');
const Project = require('./Project');
const ApprovalRequest = require('./ApprovalRequest');

// Function to initialize models with the database connection
function initializeModels(sequelize) {
  const models = {
    Deliverable: Deliverable(sequelize, DataTypes),
    Sprint: Sprint(sequelize, DataTypes),
    DeliverableSprint: DeliverableSprint(sequelize, DataTypes),
    Signoff: Signoff(sequelize, DataTypes),
    AuditLog: AuditLog(sequelize, DataTypes),
    User: User(sequelize, DataTypes),
    UserProfile: UserProfile(sequelize, DataTypes),
    RefreshToken: RefreshToken(sequelize, DataTypes),
    UserSettings: UserSettings(sequelize, DataTypes),
    Notification: Notification(sequelize, DataTypes),
    Project: Project(sequelize, DataTypes),
    ApprovalRequest: ApprovalRequest(sequelize, DataTypes)
  };

  // Set up associations
  Object.keys(models).forEach(modelName => {
    if (models[modelName].associate) {
      models[modelName].associate(models);
    }
  });

  return models;
}

// Initialize models with the database connection
const models = initializeModels(database.sequelize);

module.exports = {
  sequelize: database.sequelize,
  ...models,
  initializeModels
};