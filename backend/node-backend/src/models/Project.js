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

  return Project;
};