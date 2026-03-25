import 'package:flutter/material.dart';
import 'package:goldfit_frontend/features/auth/models/user_model.dart';
import 'package:goldfit_frontend/shared/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthViewModel(this._authRepository) {
    checkAuthState();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkAuthState() async {
    _setLoading(true);
    _currentUser = await _authRepository.getCurrentUser();
    _setLoading(false);
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      _setError('Google Sign-In cancelled');
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithEmail(email, password);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      _setError('Invalid email or password');
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password, String name) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.registerWithEmail(email, password, name);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      _setError('Registration failed');
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
// Thêm phương thức này vào class AuthViewModel

  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
      );

      final result = await _authRepository.updateUser(updatedUser);

      if (result != null) {
        _currentUser = result;
        _setLoading(false);
        return true;
      }

      _setError('Failed to update profile');
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.updateEmail(_currentUser!.id, newEmail);

      if (result != null) {
        _currentUser = result;
        _setLoading(false);
        return true;
      }

      _setError('Failed to update email');
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.updatePassword(
        _currentUser!.id,
        currentPassword,
        newPassword,
      );

      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = null;
      _error = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
  // Thêm phương thức này vào class AuthViewModel

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
}