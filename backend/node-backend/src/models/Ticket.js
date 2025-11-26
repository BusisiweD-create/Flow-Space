module.exports = (sequelize, DataTypes) => {
  const Ticket = sequelize.define('Ticket', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    ticket_id: {
      type: DataTypes.STRING(100),
      allowNull: false,
      unique: true,
    },
    ticket_key: {
      type: DataTypes.STRING(100),
    },
    summary: {
      type: DataTypes.STRING(500),
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
    },
    status: {
      type: DataTypes.STRING(50),
      defaultValue: 'To Do',
    },
    issue_type: {
      type: DataTypes.STRING(50),
      defaultValue: 'task',
    },
    priority: {
      type: DataTypes.STRING(50),
      defaultValue: 'medium',
    },
    assignee: {
      type: DataTypes.STRING(255),
    },
    reporter: {
      type: DataTypes.STRING(255),
    },
    sprint_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    project_id: {
      type: DataTypes.INTEGER,
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
    updated_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  }, {
    tableName: 'tickets',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  });

  Ticket.associate = function(models) {
    Ticket.belongsTo(models.Sprint, { foreignKey: 'sprint_id', as: 'sprint', constraints: false });
    Ticket.belongsTo(models.Project, { foreignKey: 'project_id', as: 'project', constraints: false });
    Ticket.hasMany(models.AuditLog, {
      foreignKey: 'entity_id',
      constraints: false,
      scope: { entity_type: 'ticket' },
      as: 'audit_logs'
    });
  };

  Ticket.afterCreate(async (ticket, options) => {
    try {
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('ticket_created', {
          id: ticket.id,
          ticket_id: ticket.ticket_id,
          ticket_key: ticket.ticket_key,
          sprint_id: ticket.sprint_id,
          summary: ticket.summary,
          status: ticket.status,
          issue_type: ticket.issue_type,
          priority: ticket.priority,
          assignee: ticket.assignee,
          reporter: ticket.reporter,
          created_at: ticket.created_at,
          updated_at: ticket.updated_at,
          timestamp: new Date()
        });
      }
    } catch (_) {}
  });

  Ticket.afterUpdate(async (ticket, options) => {
    try {
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('ticket_updated', {
          id: ticket.id,
          ticket_id: ticket.ticket_id,
          ticket_key: ticket.ticket_key,
          sprint_id: ticket.sprint_id,
          summary: ticket.summary,
          status: ticket.status,
          issue_type: ticket.issue_type,
          priority: ticket.priority,
          assignee: ticket.assignee,
          reporter: ticket.reporter,
          changes: ticket.changed(),
          created_at: ticket.created_at,
          updated_at: ticket.updated_at,
          timestamp: new Date()
        });
      }
    } catch (_) {}
  });

  Ticket.afterDestroy(async (ticket, options) => {
    try {
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('ticket_deleted', {
          id: ticket.id,
          ticket_id: ticket.ticket_id,
          ticket_key: ticket.ticket_key,
          sprint_id: ticket.sprint_id,
          summary: ticket.summary,
          deleted_by: options && options.deletedBy,
          timestamp: new Date()
        });
      }
    } catch (_) {}
  });

  return Ticket;
};
