/// User model for the application
/// Represents user data with role information and authentication details

// ignore_for_file: dangling_library_doc_comments

class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? company;
  final String role;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Enhanced profile fields
  final String? headline;
  final String? skills; // JSON string of skills
  final int? experienceYears;
  final String? education; // JSON string of education
  final String? socialLinks; // JSON string of social links
  final String? availabilityStatus;
  final String? timezone;
  final String? preferredLanguage;
  final bool? isEmailVerified;
  final bool? isPhoneVerified;
  final bool? verificationBadge;
  final String? profileVisibility;
  final bool? showEmail;
  final bool? showPhone;
  final DateTime? lastActiveAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.company,
    required this.role,
    required this.isActive,
    required this.isVerified,
    this.lastLogin,
    required this.createdAt,
    this.updatedAt,
    
    // Enhanced profile fields
    this.headline,
    this.skills,
    this.experienceYears,
    this.education,
    this.socialLinks,
    this.availabilityStatus,
    this.timezone,
    this.preferredLanguage,
    this.isEmailVerified,
    this.isPhoneVerified,
    this.verificationBadge,
    this.profileVisibility,
    this.showEmail,
    this.showPhone,
    this.lastActiveAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      company: json['company'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      
      // Enhanced profile fields
      headline: json['headline'] as String?,
      skills: json['skills'] as String?,
      experienceYears: json['experience_years'] as int?,
      education: json['education'] as String?,
      socialLinks: json['social_links'] as String?,
      availabilityStatus: json['availability_status'] as String?,
      timezone: json['timezone'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
      isEmailVerified: json['is_email_verified'] as bool?,
      isPhoneVerified: json['is_phone_verified'] as bool?,
      verificationBadge: json['verification_badge'] as bool?,
      profileVisibility: json['profile_visibility'] as String?,
      showEmail: json['show_email'] as bool?,
      showPhone: json['show_phone'] as bool?,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'role': role,
      'is_active': isActive,
      'is_verified': isVerified,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      
      // Enhanced profile fields
      'headline': headline,
      'skills': skills,
      'experience_years': experienceYears,
      'education': education,
      'social_links': socialLinks,
      'availability_status': availabilityStatus,
      'timezone': timezone,
      'preferred_language': preferredLanguage,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'verification_badge': verificationBadge,
      'profile_visibility': profileVisibility,
      'show_email': showEmail,
      'show_phone': showPhone,
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? company,
    String? role,
    bool? isActive,
    bool? isVerified,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    
    // Enhanced profile fields
    String? headline,
    String? skills,
    int? experienceYears,
    String? education,
    String? socialLinks,
    String? availabilityStatus,
    String? timezone,
    String? preferredLanguage,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? verificationBadge,
    String? profileVisibility,
    bool? showEmail,
    bool? showPhone,
    DateTime? lastActiveAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      
      // Enhanced profile fields
      headline: headline ?? this.headline,
      skills: skills ?? this.skills,
      experienceYears: experienceYears ?? this.experienceYears,
      education: education ?? this.education,
      socialLinks: socialLinks ?? this.socialLinks,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      timezone: timezone ?? this.timezone,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, firstName: $firstName, lastName: $lastName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.company == company &&
        other.role == role &&
        other.isActive == isActive &&
        other.isVerified == isVerified &&
        other.lastLogin == lastLogin &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      firstName,
      lastName,
      company,
      role,
      isActive,
      isVerified,
      lastLogin,
      createdAt,
      updatedAt,
    );
  }


}

class UserCreate {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? company;
  final String role;

  UserCreate({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.company,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'role': role,
    };
  }
}

class UserLogin {
  final String email;
  final String password;

  UserLogin({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;
  final String refreshToken;
  final int expiresIn;
  final User user;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}