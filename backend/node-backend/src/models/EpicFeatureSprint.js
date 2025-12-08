module.exports = (sequelize, DataTypes) => {
  const EpicFeatureSprint = sequelize.define('EpicFeatureSprint', {
    epic_feature_id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      references: {
        model: 'epic_features',
        key: 'id'
      }
    },
    sprint_id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      references: {
        model: 'sprints',
        key: 'id'
      }
    },
    contribution_percentage: {
      type: DataTypes.INTEGER,
      defaultValue: 100
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'epic_feature_sprints',
    underscored: true,
    timestamps: false
  });

  EpicFeatureSprint.associate = function(models) {
    EpicFeatureSprint.belongsTo(models.EpicFeature, {
      foreignKey: 'epic_feature_id'
    });
    EpicFeatureSprint.belongsTo(models.Sprint, {
      foreignKey: 'sprint_id'
    });
  };

  return EpicFeatureSprint;
};
