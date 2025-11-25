module.exports = (sequelize, DataTypes) => {
  const Sprint = sequelize.define('Sprint', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    project_id: {
      type: DataTypes.UUID
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT
    },
    start_date: {
      type: DataTypes.DATE
    },
    end_date: {
      type: DataTypes.DATE
    },
    planned_points: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    committed_points: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    completed_points: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    carried_over_points: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    added_during_sprint: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    removed_during_sprint: {
      type: DataTypes.INTEGER,
      defaultValue: 0
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
    defects_opened: {
      type: DataTypes.INTEGER
    },
    defects_closed: {
      type: DataTypes.INTEGER
    },
    defect_severity_mix: {
      type: DataTypes.JSON
    },
    code_review_completion: {
      type: DataTypes.INTEGER
    },
    documentation_status: {
      type: DataTypes.STRING(50)
    },
    uat_notes: {
      type: DataTypes.TEXT
    },
    uat_pass_rate: {
      type: DataTypes.INTEGER
    },
    risks_identified: {
      type: DataTypes.INTEGER
    },
    risks_mitigated: {
      type: DataTypes.INTEGER
    },
    blockers: {
      type: DataTypes.TEXT
    },
    decisions: {
      type: DataTypes.TEXT
    },
    status: {
      type: DataTypes.STRING(50),
      defaultValue: 'planning'
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
    },
    reviewed_at: {
      type: DataTypes.DATE
    }
  }, {
    tableName: 'sprints',
    underscored: true,
    timestamps: false
  });

  Sprint.associate = function(models) {
    Sprint.belongsTo(models.Project, {
      foreignKey: 'project_id',
      as: 'project'
    });
    Sprint.belongsToMany(models.Deliverable, {
      through: models.DeliverableSprint,
      foreignKey: 'sprint_id',
      as: 'deliverables'
    });

    Sprint.hasMany(models.Signoff, {
      foreignKey: 'entity_id',
      constraints: false,
      scope: {
        entity_type: 'sprint'
      },
      as: 'signoffs'
    });

    Sprint.hasMany(models.AuditLog, {
      foreignKey: 'entity_id',
      constraints: false,
      scope: {
        entity_type: 'sprint'
      },
      as: 'audit_logs'
    });
  };

  // Real-time event hooks
  Sprint.afterCreate(async (sprint, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('sprint_created', {
          id: sprint.id,
          name: sprint.name,
          status: sprint.status,
          created_by: sprint.created_by,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in sprint afterCreate hook:', error);
    }
  });

  Sprint.afterUpdate(async (sprint, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('sprint_updated', {
          id: sprint.id,
          name: sprint.name,
          status: sprint.status,
          updated_by: options.updatedBy || sprint.updated_by,
          changes: sprint.changed(),
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in sprint afterUpdate hook:', error);
    }
  });

  Sprint.afterDestroy(async (sprint, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('sprint_deleted', {
          id: sprint.id,
          name: sprint.name,
          deleted_by: options.deletedBy,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in sprint afterDestroy hook:', error);
    }
  });

  return Sprint;
};