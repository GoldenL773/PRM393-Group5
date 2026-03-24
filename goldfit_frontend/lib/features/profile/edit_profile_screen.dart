import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:goldfit_frontend/features/auth/auth_viewmodel.dart';
import 'package:goldfit_frontend/features/auth/models/user_model.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authVm = context.read<AuthViewModel>();

    // TODO: Upload image to server if needed
    // For now, we'll just update the display name
    final success = await authVm.updateUserProfile(
      displayName: _nameController.text.trim(),
      // photoUrl: _selectedImagePath, // Would need upload logic
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFFC5A028),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVm.error ?? 'Failed to update profile'),
          backgroundColor: Colors.red.shade400,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF7),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        backgroundColor: const Color(0xFFFCFBF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC5A028),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Section
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFC5A028).withOpacity(0.1),
                        image: _selectedImagePath != null
                            ? DecorationImage(
                          image: FileImage(File(_selectedImagePath!)),
                          fit: BoxFit.cover,
                        )
                            : user?.photoUrl != null
                            ? DecorationImage(
                          image: NetworkImage(user!.photoUrl!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _selectedImagePath == null && user?.photoUrl == null
                          ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFFC5A028),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A028),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Tap to change photo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: const Color(0xFFC5A028),
                ),
              ),

              const SizedBox(height: 32),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Email Field (Read-only)
              TextFormField(
                initialValue: user?.email ?? '',
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                    borderSide: BorderSide(color: Color(0xFFE6E1D6)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Account Type
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFE6E1D6)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      color: Color(0xFFC5A028),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Type',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF6B6A65),
                            ),
                          ),
                          Text(
                            user?.provider == AuthProvider.google
                                ? 'Google Account'
                                : 'Email Account',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user?.provider == AuthProvider.google
                            ? Colors.blue.shade50
                            : const Color(0xFFC5A028).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        user?.provider == AuthProvider.google
                            ? 'Connected'
                            : 'Email',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: user?.provider == AuthProvider.google
                              ? Colors.blue.shade700
                              : const Color(0xFFC5A028),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Note about Google account
              if (user?.provider == AuthProvider.google)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your profile photo is synced with Google. Changes may take a moment to reflect.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}