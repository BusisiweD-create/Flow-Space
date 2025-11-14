module.exports = (sequelize, DataTypes) => {
  const Project = sequelize.define('Project', {
    id: {
      type: DataTypes.UUID,
      primaryKey: true,
      defaultValue: DataTypes.UUIDV4
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true
      }
    },
    key: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    project_type: {
      type: DataTypes.STRING,
      allowNull: true,
      defaultValue: 'software'
    },
    status: {
      type: DataTypes.STRING,
      allowNull: true,
      defaultValue: 'active'
    },
    created_by: {
      type: DataTypes.UUID,
      allowNull: true
    }
  }, {
    tableName: 'projects',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  // Associations
  Project.associate = (models) => {
    Project.belongsTo(models.User, {
      foreignKey: 'created_by',
      as: 'creator'
    });
    
    Project.hasMany(models.Sprint, {
      foreignKey: 'project_id',
      as: 'sprints'
    });
  };

  // Real-time event hooks
  Project.afterCreate(async (project, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('project_created', {
          id: project.id,
          name: project.name,
          key: project.key,
          created_by: project.created_by,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in project afterCreate hook:', error);
    }
  });

  Project.afterUpdate(async (project, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('project_updated', {
          id: project.id,
          name: project.name,
          key: project.key,
          updated_by: options.updatedBy || project.updated_by,
          changes: project.changed(),
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in project afterUpdate hook:', error);
    }
  });

  Project.afterDestroy(async (project, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('project_deleted', {
          id: project.id,
          name: project.name,
          key: project.key,
          deleted_by: options.deletedBy,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in project afterDestroy hook:', error);
    }
  });

  return Project;
};