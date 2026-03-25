import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:goldfit_frontend/core/database/database_manager.dart';
import 'package:goldfit_frontend/core/database/database_constants.dart';
import 'package:goldfit_frontend/features/auth/models/user_model.dart';
import 'package:goldfit_frontend/shared/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseManager _dbManager;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  String? _currentSessionToken;

  AuthRepositoryImpl(this._dbManager);

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final existingUser = await _findUserByEmail(googleUser.email);

        if (existingUser != null) {
          _currentUser = existingUser;
          await _updateLastLogin(existingUser.id);
        } else {
          _currentUser = UserModel.fromGoogleSignIn(googleUser);
          await _saveUser(_currentUser!);
        }

        _currentSessionToken = await createSession(_currentUser!.id);
        return _currentUser;
      }
      return null;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final user = await _findUserByEmail(email);

      if (user == null) {
        throw Exception('User not found');
      }

      if (user.provider != AuthProvider.email) {
        throw Exception('Please sign in with ${user.provider.name}');
      }

      // In production, verify password hash
      if (password.isEmpty) {
        throw Exception('Invalid password');
      }

      _currentUser = user;
      await _updateLastLogin(user.id);
      _currentSessionToken = await createSession(user.id);

      return user;
    } catch (e) {
      debugPrint('Email sign-in failed: $e');
      throw Exception('Sign-in failed: $e');
    }
  }

  @override
  Future<UserModel?> registerWithEmail(String email, String password, String name) async {
    try {
      final existingUser = await _findUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Email already registered');
      }

      _currentUser = UserModel(
        id: _generateUserId(),
        email: email,
        displayName: name,
        photoUrl: null,
        provider: AuthProvider.email,
        emailVerified: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _saveUser(_currentUser!, passwordHash: password);
      _currentSessionToken = await createSession(_currentUser!.id);

      return _currentUser;
    } catch (e) {
      debugPrint('Registration failed: $e');
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_currentSessionToken != null) {
        await revokeSession(_currentSessionToken!);
      }
      await _googleSignIn.signOut();
      _currentUser = null;
      _currentSessionToken = null;
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    // Try to restore from last valid session stored in preferences
    // For now, return null to require login
    return null;
  }

  @override
  Future<String?> createSession(String userId) async {
    final db = await _dbManager.database;
    final sessionId = _generateSessionId();
    final sessionToken = _generateSessionToken();
    final expiresAt = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;

    await db.insert(
      DatabaseConstants.tableUserSessions,
      {
        DatabaseConstants.columnSessionId: sessionId,
        DatabaseConstants.columnUserId: userId,
        DatabaseConstants.columnSessionToken: sessionToken,
        DatabaseConstants.columnExpiresAt: expiresAt,
        DatabaseConstants.columnIsRevoked: 0,
        DatabaseConstants.columnCreatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return sessionToken;
  }

  @override
  Future<bool> validateSession(String sessionToken) async {
    final db = await _dbManager.database;
    final results = await db.query(
      DatabaseConstants.tableUserSessions,
      where: '${DatabaseConstants.columnSessionToken} = ? AND '
          '${DatabaseConstants.columnIsRevoked} = 0 AND '
          '${DatabaseConstants.columnExpiresAt} > ?',
      whereArgs: [sessionToken, DateTime.now().millisecondsSinceEpoch],
    );

    return results.isNotEmpty;
  }

  @override
  Future<void> revokeSession(String sessionToken) async {
    final db = await _dbManager.database;
    await db.update(
      DatabaseConstants.tableUserSessions,
      {DatabaseConstants.columnIsRevoked: 1},
      where: '${DatabaseConstants.columnSessionToken} = ?',
      whereArgs: [sessionToken],
    );
  }

  @override
  Stream<UserModel?> get authStateChanges async* {
    yield _currentUser;
  }

  Future<UserModel?> _findUserByEmail(String email) async {
    final db = await _dbManager.database;
    final results = await db.query(
      DatabaseConstants.tableUsers,
      where: '${DatabaseConstants.columnEmail} = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }

  Future<void> _saveUser(UserModel user, {String? passwordHash}) async {
    final db = await _dbManager.database;
    await db.insert(
      DatabaseConstants.tableUsers,
      {
        DatabaseConstants.columnUserId: user.id,
        DatabaseConstants.columnEmail: user.email.toLowerCase(),
        DatabaseConstants.columnDisplayName: user.displayName,
        DatabaseConstants.columnPhotoUrl: user.photoUrl,
        DatabaseConstants.columnAuthProvider: user.provider.name,
        DatabaseConstants.columnLastLoginAt: user.lastLoginAt.millisecondsSinceEpoch,
        DatabaseConstants.columnEmailVerified: user.emailVerified ? 1 : 0,
        DatabaseConstants.columnPasswordHash: passwordHash,
        DatabaseConstants.columnCreatedAt: user.createdAt.millisecondsSinceEpoch,
        DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
// Thêm phương thức này vào class AuthRepositoryImpl

  @override
  Future<UserModel?> updateUser(UserModel user) async {
    try {
      final db = await _dbManager.database;

      await db.update(
        DatabaseConstants.tableUsers,
        {
          DatabaseConstants.columnDisplayName: user.displayName,
          DatabaseConstants.columnPhotoUrl: user.photoUrl,
          DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [user.id],
      );

      if (_currentUser?.id == user.id) {
        _currentUser = user;
      }

      return user;
    } catch (e) {
      debugPrint('Update user failed: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<UserModel?> updateEmail(String userId, String newEmail) async {
    try {
      final db = await _dbManager.database;
      
      final existingUser = await _findUserByEmail(newEmail);
      if (existingUser != null && existingUser.id != userId) {
        throw Exception('Email already in use');
      }

      await db.update(
        DatabaseConstants.tableUsers,
        {
          DatabaseConstants.columnEmail: newEmail.toLowerCase(),
          DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [userId],
      );

      if (_currentUser?.id == userId) {
        _currentUser = _currentUser!.copyWith(email: newEmail);
      }

      return _currentUser;
    } catch (e) {
      debugPrint('Update email failed: $e');
      throw Exception('Failed to update email: $e');
    }
  }

  @override
  Future<bool> updatePassword(String userId, String currentPassword, String newPassword) async {
    try {
      final db = await _dbManager.database;
      
      final results = await db.query(
        DatabaseConstants.tableUsers,
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) {
        throw Exception('User not found');
      }

      final userData = results.first;
      final storedPassword = userData[DatabaseConstants.columnPasswordHash] as String?;

      if (storedPassword != currentPassword) {
        throw Exception('Current password is incorrect');
      }

      await db.update(
        DatabaseConstants.tableUsers,
        {
          DatabaseConstants.columnPasswordHash: newPassword,
          DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [userId],
      );

      return true;
    } catch (e) {
      debugPrint('Update password failed: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    final db = await _dbManager.database;
    await db.update(
      DatabaseConstants.tableUsers,
      {
        DatabaseConstants.columnLastLoginAt: DateTime.now().millisecondsSinceEpoch,
        DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DatabaseConstants.columnUserId} = ?',
      whereArgs: [userId],
    );
  }

  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  String _generateSessionId() {
    return 'sess_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  String _generateSessionToken() {
    return 'token_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}';
  }
  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('No user logged in');
      }

      if (_currentUser!.provider != AuthProvider.email) {
        throw Exception('Password change only available for email accounts');
      }

      final db = await _dbManager.database;

      // Verify current password
      final user = await _findUserByEmail(_currentUser!.email);
      if (user == null) {
        throw Exception('User not found');
      }

      // In production, you would verify the password hash
      // For demo, we'll just check if current password is provided
      if (currentPassword.isEmpty) {
        throw Exception('Current password is required');
      }

      // Update password (in production, you'd hash the new password)
      await db.update(
        DatabaseConstants.tableUsers,
        {
          DatabaseConstants.columnPasswordHash: newPassword, // Should be hashed in production
          DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [_currentUser!.id],
      );

      return true;
    } catch (e) {
      debugPrint('Change password failed: $e');
      throw Exception('Failed to change password: $e');
    }
  }
}
// Thêm phương thức này vào class AuthRepositoryImpl

