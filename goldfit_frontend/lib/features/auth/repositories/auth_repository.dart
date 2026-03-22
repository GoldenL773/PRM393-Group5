import 'package:goldfit_frontend/features/auth/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signInWithGoogle();
  Future<UserModel?> signInWithEmail(String email, String password);
  Future<UserModel?> registerWithEmail(String email, String password, String name);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<String?> createSession(String userId);
  Future<bool> validateSession(String sessionToken);
  Future<void> revokeSession(String sessionToken);
  Stream<UserModel?> get authStateChanges;
}