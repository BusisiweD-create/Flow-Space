module.exports = (sequelize, DataTypes) => {
  const Signoff = sequelize.define('Signoff', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    entity_type: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    entity_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    signer_name: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    signer_email: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    signer_role: {
      type: DataTypes.STRING(100)
    },
    signer_company: {
      type: DataTypes.STRING(255)
    },
    decision: {
      type: DataTypes.STRING(50),
      defaultValue: 'pending'
    },
    comments: {
      type: DataTypes.TEXT
    },
    change_request_details: {
      type: DataTypes.TEXT
    },
    ip_address: {
      type: DataTypes.STRING(50)
    },
    user_agent: {
      type: DataTypes.STRING(500)
    },
    signature_hash: {
      type: DataTypes.STRING(500)
    },
    submitted_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    reviewed_at: {
      type: DataTypes.DATE
    },
    responded_at: {
      type: DataTypes.DATE
    }
  }, {
    tableName: 'signoffs',
    underscored: true,
    timestamps: false
  });

  Signoff.associate = function(models) {
    Signoff.belongsTo(models.Deliverable, {
      foreignKey: 'entity_id',
      constraints: false,
      as: 'deliverable'
    });

    Signoff.belongsTo(models.Sprint, {
      foreignKey: 'entity_id',
      constraints: false,
      as: 'sprint'
    });

    Signoff.hasMany(models.AuditLog, {
      foreignKey: 'entity_id',
      constraints: false,
      scope: {
        entity_type: 'signoff'
      },
      as: 'audit_logs'
    });
  };

  // Helper method to get the entity being signed off
  Signoff.prototype.getEntity = async function() {
    if (this.entity_type === 'deliverable') {
      return await this.getDeliverable();
    } else if (this.entity_type === 'sprint') {
      return await this.getSprint();
    }
    return null;
  };

  return Signoff;
};