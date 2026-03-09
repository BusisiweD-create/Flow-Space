module.exports = (sequelize, DataTypes) => {
  const DeliverableArtifact = sequelize.define('DeliverableArtifact', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    deliverable_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    filename: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    original_name: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    file_type: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    file_size: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    url: {
      type: DataTypes.STRING(500),
      allowNull: false
    },
    uploaded_by: {
      type: DataTypes.UUID,
      allowNull: false
    },
    uploader_name: {
      type: DataTypes.STRING(255)
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'deliverable_artifacts',
    underscored: true,
    timestamps: true,
    updatedAt: false
  });

  DeliverableArtifact.associate = function(models) {
    DeliverableArtifact.belongsTo(models.Deliverable, {
      foreignKey: 'deliverable_id',
      as: 'deliverable'
    });
    DeliverableArtifact.belongsTo(models.User, {
      foreignKey: 'uploaded_by',
      as: 'uploader'
    });
  };

  return DeliverableArtifact;
};
