module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    id: {
      type: DataTypes.UUID,
      primaryKey: true,
      defaultValue: DataTypes.UUIDV4
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true
    },
    hashed_password: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    first_name: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    last_name: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    company: {
      type: DataTypes.STRING(100)
    },
    role: {
      type: DataTypes.STRING(50),
      defaultValue: 'user'
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    is_verified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    verification_token: {
      type: DataTypes.STRING(255)
    },
    reset_token: {
      type: DataTypes.STRING(255)
    },
    last_login: {
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
    tableName: 'users',
    underscored: true,
    timestamps: false
  });

  User.associate = function(models) {
    User.hasOne(models.UserProfile, {
      foreignKey: 'user_id',
      as: 'profile'
    });

    User.hasMany(models.RefreshToken, {
      foreignKey: 'user_id',
      as: 'refresh_tokens'
    });

    User.hasMany(models.AuditLog, {
      foreignKey: 'user_id',
      as: 'audit_logs'
    });

    User.hasMany(models.Notification, {
      foreignKey: 'recipient_id',
      as: 'notifications_received'
    });

    User.hasMany(models.Notification, {
      foreignKey: 'sender_id',
      as: 'notifications_sent'
    });
  };

  // Real-time event hooks
  User.afterCreate(async (user, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('user_created', {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in user afterCreate hook:', error);
    }
  });

  User.afterUpdate(async (user, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        const changes = user.changed();
        global.realtimeEvents.emit('user_updated', {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          updated_by: options.updatedBy,
          changes,
          timestamp: new Date()
        });

        // Special handling for role changes
        if (changes && changes.includes('role')) {
          global.realtimeEvents.emit('user_role_changed', {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            old_role: user.previous('role'),
            new_role: user.role,
            changed_by: options.updatedBy,
            timestamp: new Date()
          });
        }
      }
    } catch (error) {
      console.error('Error in user afterUpdate hook:', error);
    }
  });

  User.afterDestroy(async (user, options) => {
    try {
      // Use global event emitter to avoid circular dependencies
      if (global.realtimeEvents) {
        global.realtimeEvents.emit('user_deleted', {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          deleted_by: options.deletedBy,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error in user afterDestroy hook:', error);
    }
  });

  return User;
};