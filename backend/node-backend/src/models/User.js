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

  return User;
};