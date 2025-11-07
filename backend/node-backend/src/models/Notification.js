module.exports = (sequelize, DataTypes) => {
  const Notification = sequelize.define('Notification', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    recipient_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    sender_id: {
      type: DataTypes.UUID,
      references: {
        model: 'users',
        key: 'id'
      }
    },
    type: {
      type: DataTypes.STRING,
      allowNull: false
    },
    message: {
      type: DataTypes.STRING,
      allowNull: false
    },
    payload: {
      type: DataTypes.JSON
    },
    is_read: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    }
  }, {
    tableName: 'notifications',
    underscored: true,
    timestamps: false
  });

  Notification.associate = function(models) {
    Notification.belongsTo(models.User, {
      foreignKey: 'recipient_id',
      as: 'recipient'
    });

    Notification.belongsTo(models.User, {
      foreignKey: 'sender_id',
      as: 'sender'
    });
  };

  return Notification;
};