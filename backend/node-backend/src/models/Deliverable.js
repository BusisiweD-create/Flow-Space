module.exports = (sequelize, DataTypes) => {
  const Deliverable = sequelize.define('Deliverable', {
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
    definition_of_done: {
      type: DataTypes.TEXT
    },
    status: {
      type: DataTypes.STRING(50),
      defaultValue: 'draft'
    },
    priority: {
      type: DataTypes.STRING(50),
      defaultValue: 'medium'
    },
    due_date: {
      type: DataTypes.DATE
    },
    created_by: {
      type: DataTypes.STRING(255)
    },
    assigned_to: {
      type: DataTypes.STRING(255)
    },
    evidence_links: {
      type: DataTypes.JSON
    },
    demo_link: {
      type: DataTypes.STRING(500)
    },
    repo_link: {
      type: DataTypes.STRING(500)
    },
    test_summary_link: {
      type: DataTypes.STRING(500)
    },
    user_guide_link: {
      type: DataTypes.STRING(500)
    },
    test_pass_rate: {
      type: DataTypes.INTEGER
    },
    code_coverage: {
      type: DataTypes.INTEGER
    },
    escaped_defects: {
      type: DataTypes.INTEGER
    },
    defect_severity_mix: {
      type: DataTypes.JSON
    },
    submitted_at: {
      type: DataTypes.DATE
    },
    approved_at: {
      type: DataTypes.DATE
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
    tableName: 'deliverables',
    underscored: true,
    timestamps: false
  });

  Deliverable.associate = function(models) {
    Deliverable.belongsToMany(models.Sprint, {
      through: models.DeliverableSprint,
      foreignKey: 'deliverable_id',
      as: 'contributing_sprints'
    });

    Deliverable.hasMany(models.Signoff, {
      foreignKey: 'entity_id',
      constraints: false,
      scope: {
        entity_type: 'deliverable'
      },
      as: 'signoffs'
    });

    Deliverable.hasMany(models.AuditLog, {
      foreignKey: 'entity_id',
      constraints: false,
      scope: {
        entity_type: 'deliverable'
      },
      as: 'audit_logs'
    });
  };

  // Real-time event hooks
  Deliverable.afterCreate(async (deliverable, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('deliverable_created', {
          id: deliverable.id,
          title: deliverable.title,
          status: deliverable.status,
          created_by: deliverable.created_by,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in deliverable afterCreate hook:', error);
    }
  });

  Deliverable.afterUpdate(async (deliverable, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('deliverable_updated', {
          id: deliverable.id,
          title: deliverable.title,
          status: deliverable.status,
          updated_by: options.updatedBy || deliverable.updated_by,
          changes: deliverable.changed(),
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in deliverable afterUpdate hook:', error);
    }
  });

  Deliverable.afterDestroy(async (deliverable, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('deliverable_deleted', {
          id: deliverable.id,
          title: deliverable.title,
          deleted_by: options.deletedBy,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in deliverable afterDestroy hook:', error);
    }
  });

  return Deliverable;
};