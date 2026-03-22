import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthProvider provider;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
    this.emailVerified = false,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserModel.fromGoogleSignIn(GoogleSignInAccount account) {
    return UserModel(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      provider: AuthProvider.google,
      emailVerified: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  // CopyWith method để tạo bản sao với các field được cập nhật
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProvider? provider,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() => {
    DatabaseConstants.columnUserId: id,
    DatabaseConstants.columnEmail: email.toLowerCase(),
    DatabaseConstants.columnDisplayName: displayName,
    DatabaseConstants.columnPhotoUrl: photoUrl,
    DatabaseConstants.columnAuthProvider: provider.name,
    DatabaseConstants.columnEmailVerified: emailVerified ? 1 : 0,
    DatabaseConstants.columnLastLoginAt: lastLoginAt.millisecondsSinceEpoch,
    DatabaseConstants.columnCreatedAt: createdAt.millisecondsSinceEpoch,
    DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json[DatabaseConstants.columnUserId],
    email: json[DatabaseConstants.columnEmail],
    displayName: json[DatabaseConstants.columnDisplayName],
    photoUrl: json[DatabaseConstants.columnPhotoUrl],
    provider: AuthProvider.values.firstWhere(
          (e) => e.name == json[DatabaseConstants.columnAuthProvider],
    ),
    emailVerified: json[DatabaseConstants.columnEmailVerified] == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      json[DatabaseConstants.columnCreatedAt],
    ),
    lastLoginAt: DateTime.fromMillisecondsSinceEpoch(
      json[DatabaseConstants.columnLastLoginAt],
    ),
  );
}

enum AuthProvider {
  google,
  email,
}