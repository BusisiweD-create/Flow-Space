import 'user_role.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? company;
  final UserRole role;
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
      id: json['id'].toString(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      company: json['company'] as String?,
      role: _parseUserRole(json['role']),
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      
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

  // Helper function to parse the user role from either an integer or a string.
  // This function is robust to handle both integer and string roles.
  static UserRole _parseUserRole(dynamic role) {
    if (role is int) {
      switch (role) {
        case 0:
          return UserRole.teamMember;
        case 1:
          return UserRole.deliveryLead;
        case 2:
          return UserRole.clientReviewer;
        case 3:
          return UserRole.systemAdmin;
        default:
          return UserRole.teamMember;
      }
    } else if (role is String) {
      switch (role.toLowerCase()) {
        case 'teammember':
          return UserRole.teamMember;
        case 'deliverylead':
          return UserRole.deliveryLead;
        case 'clientreviewer':
          return UserRole.clientReviewer;
        case 'systemadmin':
          return UserRole.systemAdmin;
        default:
          return UserRole.teamMember;
      }
    }
    return UserRole.teamMember;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'role': role.toString().split('.').last,
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
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? company,
    UserRole? role,
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
  final UserRole role;

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
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'role': role.toString().split('.').last.toLowerCase(),
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
    // Handle both response formats: backend returns 'token' instead of 'access_token'
    final String accessToken = json['access_token'] as String? ?? json['token'] as String;
    
    return TokenResponse(
      accessToken: accessToken,
      tokenType: json['token_type'] as String? ?? 'bearer',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: json['expires_in'] as int? ?? 3600,
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