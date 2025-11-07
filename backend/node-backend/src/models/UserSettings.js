module.exports = (sequelize, DataTypes) => {
  const UserSettings = sequelize.define('UserSettings', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    user_id: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    dark_mode: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    notifications_enabled: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    language: {
      type: DataTypes.STRING(50),
      defaultValue: 'English'
    },
    sync_on_mobile_data: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    auto_backup: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    share_analytics: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    allow_notifications: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
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
    tableName: 'user_settings',
    underscored: true,
    timestamps: false
  });

  return UserSettings;
};