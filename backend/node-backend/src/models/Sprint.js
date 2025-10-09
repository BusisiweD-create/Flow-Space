module.exports = (sequelize, DataTypes) => {
  const Sprint = sequelize.define('Sprint', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
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

  return Sprint;
};