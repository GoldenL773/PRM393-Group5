import 'package:flutter/material.dart';
import 'package:goldfit_frontend/features/auth/auth_viewmodel.dart';
import 'package:goldfit_frontend/shared/utils/routes.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;

  SettingsViewModel(this._authViewModel);

  AuthViewModel get authViewModel => _authViewModel;

  Future<void> handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Log Out",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authViewModel.signOut();
      
      if (!context.mounted) return;
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.auth,
        (route) => false,
      );
    }
  }

  Future<void> handleUpdateEmail(BuildContext context, String newEmail) async {
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      _showSnackBar(
        context,
        "Please enter a valid email address",
        Colors.red,
      );
      return;
    }

    final success = await _authViewModel.updateEmail(newEmail);
    
    if (!context.mounted) return;
    
    Navigator.pop(context);
    
    _showSnackBar(
      context,
      success 
        ? "Email updated successfully" 
        : _authViewModel.error ?? "Failed to update email",
      success ? Colors.green : Colors.red,
    );
  }

  Future<void> handleUpdatePassword(
    BuildContext context,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (currentPassword.isEmpty) {
      _showSnackBar(
        context,
        "Please enter your current password",
        Colors.red,
      );
      return;
    }

    if (newPassword.isEmpty || newPassword.length < 6) {
      _showSnackBar(
        context,
        "New password must be at least 6 characters",
        Colors.red,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar(
        context,
        "Passwords do not match",
        Colors.red,
      );
      return;
    }
    
    final success = await _authViewModel.updatePassword(
      currentPassword,
      newPassword,
    );
    
    if (!context.mounted) return;
    
    Navigator.pop(context);
    
    _showSnackBar(
      context,
      success 
        ? "Password updated successfully" 
        : _authViewModel.error ?? "Failed to update password",
      success ? Colors.green : Colors.red,
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
