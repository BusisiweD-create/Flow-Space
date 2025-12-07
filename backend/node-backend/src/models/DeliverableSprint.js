module.exports = (sequelize, DataTypes) => {
  const DeliverableSprint = sequelize.define('DeliverableSprint', {
    deliverable_id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      references: {
        model: 'deliverables',
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
    tableName: 'deliverable_sprints',
    underscored: true,
    timestamps: false
  });

  DeliverableSprint.associate = function(models) {
    DeliverableSprint.belongsTo(models.Deliverable, {
      foreignKey: 'deliverable_id'
    });
    DeliverableSprint.belongsTo(models.Sprint, {
      foreignKey: 'sprint_id'
    });
  };

  return DeliverableSprint;
};