module.exports = (sequelize, DataTypes) => {
  const UserProfile = sequelize.define('UserProfile', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id'
      },
      unique: true
    },
    first_name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    last_name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    phone_number: {
      type: DataTypes.STRING
    },
    profile_picture: {
      type: DataTypes.STRING
    },
    bio: {
      type: DataTypes.TEXT
    },
    job_title: {
      type: DataTypes.STRING
    },
    company: {
      type: DataTypes.STRING
    },
    location: {
      type: DataTypes.STRING
    },
    website: {
      type: DataTypes.STRING
    },
    date_of_birth: {
      type: DataTypes.DATE
    },
    headline: {
      type: DataTypes.STRING
    },
    skills: {
      type: DataTypes.JSON
    },
    experience_years: {
      type: DataTypes.INTEGER
    },
    education: {
      type: DataTypes.JSON
    },
    social_links: {
      type: DataTypes.JSON
    },
    availability_status: {
      type: DataTypes.STRING,
      defaultValue: 'available'
    },
    timezone: {
      type: DataTypes.STRING
    },
    preferred_language: {
      type: DataTypes.STRING,
      defaultValue: 'en'
    },
    is_email_verified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    is_phone_verified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    verification_badge: {
      type: DataTypes.STRING
    },
    profile_visibility: {
      type: DataTypes.STRING,
      defaultValue: 'public'
    },
    show_email: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    show_phone: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    },
    last_active_at: {
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
    tableName: 'user_profiles',
    underscored: true,
    timestamps: false
  });

  UserProfile.associate = function(models) {
    UserProfile.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user'
    });
  };

  return UserProfile;
};