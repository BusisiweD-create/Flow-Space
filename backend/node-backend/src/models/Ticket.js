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
    timestamps: false,
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

  return Ticket;
};