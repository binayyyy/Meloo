import '../core/json_value.dart';

enum UserRole { attendee, organizer, vendor, sponsor, admin }

UserRole userRoleFromApi(String value) {
  return UserRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => UserRole.attendee,
  );
}

class UserProfileModel {
  const UserProfileModel({
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.bio,
  });

  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? bio;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: nullableStringValue(json['fullName']),
      avatarUrl: nullableStringValue(json['avatarUrl']),
      phone: nullableStringValue(json['phone']),
      bio: nullableStringValue(json['bio']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'bio': bio,
    };
  }
}

class UserSettingsModel {
  const UserSettingsModel({
    required this.notificationsEnabled,
    required this.marketingEnabled,
    required this.privacyLevel,
    required this.aiAssistEnabled,
  });

  final bool notificationsEnabled;
  final bool marketingEnabled;
  final String privacyLevel;
  final bool aiAssistEnabled;

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      notificationsEnabled: boolValue(
        json['notificationsEnabled'],
        fallback: true,
      ),
      marketingEnabled: boolValue(json['marketingEnabled']),
      privacyLevel: stringValue(
        json['privacyLevel'],
        fallback: 'contacts_only',
      ),
      aiAssistEnabled: boolValue(json['aiAssistEnabled']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'marketingEnabled': marketingEnabled,
      'privacyLevel': privacyLevel,
      'aiAssistEnabled': aiAssistEnabled,
    };
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.profile,
    required this.settings,
  });

  final String id;
  final String email;
  final UserRole role;
  final String status;
  final UserProfileModel? profile;
  final UserSettingsModel? settings;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: stringValue(json['id']),
      email: stringValue(json['email']),
      role: userRoleFromApi(stringValue(json['role'], fallback: 'attendee')),
      status: stringValue(json['status'], fallback: 'active'),
      profile: json['profile'] == null
          ? null
          : UserProfileModel.fromJson(
              Map<String, dynamic>.from(json['profile'] as Map),
            ),
      settings: json['settings'] == null
          ? null
          : UserSettingsModel.fromJson(
              Map<String, dynamic>.from(json['settings'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'status': status,
      'profile': profile?.toJson(),
      'settings': settings?.toJson(),
    };
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.refreshTokenExpiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresIn;
  final int refreshTokenExpiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: stringValue(json['accessToken']),
      refreshToken: stringValue(json['refreshToken']),
      accessTokenExpiresIn: intValue(json['accessTokenExpiresIn']),
      refreshTokenExpiresIn: intValue(json['refreshTokenExpiresIn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiresIn': accessTokenExpiresIn,
      'refreshTokenExpiresIn': refreshTokenExpiresIn,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.tokens,
  });

  final UserModel user;
  final AuthTokens tokens;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      tokens: AuthTokens.fromJson(
        Map<String, dynamic>.from(json['tokens'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tokens': tokens.toJson(),
    };
  }
}

class ForgotPasswordResult {
  const ForgotPasswordResult({
    required this.message,
    this.debugResetToken,
  });

  final String message;
  final String? debugResetToken;

  factory ForgotPasswordResult.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResult(
      message: nullableStringValue(json['message']) ??
          'If an account exists, a reset link has been prepared.',
      debugResetToken: nullableStringValue(json['debugResetToken']),
    );
  }
}
