module.exports = (sequelize, DataTypes) => {
  const ApprovalRequest = sequelize.define('ApprovalRequest', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  deliverable_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'deliverables',
      key: 'id',
    },
  },
  requested_by: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  approved_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  status: {
    type: DataTypes.STRING,
    defaultValue: 'pending',
    allowNull: false,
    validate: {
      isIn: [['pending', 'approved', 'rejected', 'reminder_sent']]
    }
  },
  comments: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  requested_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  approved_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  rejected_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  reminder_sent_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  due_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'approval_requests',
  timestamps: true,
  underscored: true,
  });

  // Associations
  ApprovalRequest.associate = (models) => {
  ApprovalRequest.belongsTo(models.Deliverable, {
    foreignKey: 'deliverable_id',
    as: 'deliverable',
  });
  
  ApprovalRequest.belongsTo(models.User, {
    foreignKey: 'requested_by',
    as: 'requester',
  });
  
  ApprovalRequest.belongsTo(models.User, {
    foreignKey: 'approved_by',
    as: 'approver',
  });
  };

  return ApprovalRequest;
};