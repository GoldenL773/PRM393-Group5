import 'package:flutter/material.dart';

class UpdatePasswordDialog extends StatelessWidget {
  final Function(String, String, String) onUpdate;

  const UpdatePasswordDialog({
    super.key,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return AlertDialog(
      title: const Text("Change Password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentPasswordController,
            decoration: const InputDecoration(
              labelText: "Current Password",
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPasswordController,
            decoration: const InputDecoration(
              labelText: "New Password",
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmPasswordController,
            decoration: const InputDecoration(
              labelText: "Confirm New Password",
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            onUpdate(
              currentPasswordController.text,
              newPasswordController.text,
              confirmPasswordController.text,
            );
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}
