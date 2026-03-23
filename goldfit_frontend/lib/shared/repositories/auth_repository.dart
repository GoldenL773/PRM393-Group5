import 'package:goldfit_frontend/features/auth/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signInWithGoogle();
  Future<UserModel?> signInWithEmail(String email, String password);
  Future<UserModel?> registerWithEmail(String email, String password, String name);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<UserModel?> updateUser(UserModel user);
  Future<UserModel?> updateEmail(String userId, String newEmail);
  Future<bool> updatePassword(String userId, String currentPassword, String newPassword);
  Future<String?> createSession(String userId);
  Future<bool> validateSession(String sessionToken);
  Future<void> revokeSession(String sessionToken);
  Stream<UserModel?> get authStateChanges;
}