module.exports = (sequelize, DataTypes) => {
  const EpicFeature = sequelize.define('EpicFeature', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    title: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT
    },
    status: {
      type: DataTypes.STRING(50),
      defaultValue: 'planning'
    },
    priority: {
      type: DataTypes.STRING(50),
      defaultValue: 'medium'
    },
    created_by: {
      type: DataTypes.STRING(255)
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    updated_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'epic_features',
    underscored: true,
    timestamps: false
  });

  EpicFeature.associate = function(models) {
    EpicFeature.belongsToMany(models.Sprint, {
      through: models.EpicFeatureSprint,
      foreignKey: 'epic_feature_id',
      as: 'linked_sprints'
    });

    EpicFeature.hasMany(models.AuditLog, {
      foreignKey: 'entity_id',
      constraints: false,
      scope: {
        entity_type: 'epic_feature'
      },
      as: 'audit_logs'
    });
  };

  EpicFeature.afterCreate(async (epicFeature) => {
    try {
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('epic_feature_created', {
          id: epicFeature.id,
          title: epicFeature.title,
          status: epicFeature.status,
          created_by: epicFeature.created_by,
          timestamp: new Date()
        });
      }
    } catch (error) {}
  });

  return EpicFeature;
};
