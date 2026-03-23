import 'package:flutter/material.dart';

class UpdateEmailDialog extends StatelessWidget {
  final String? currentEmail;
  final Function(String) onUpdate;

  const UpdateEmailDialog({
    super.key,
    this.currentEmail,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController(text: currentEmail);

    return AlertDialog(
      title: const Text("Update Email"),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: "New Email",
          hintText: "Enter new email address",
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final newEmail = emailController.text.trim();
            onUpdate(newEmail);
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}
