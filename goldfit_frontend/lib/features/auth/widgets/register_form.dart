import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/auth/auth_viewmodel.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Focus nodes for better UX
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // Name validation
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }

    value = value.trim();

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
    return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // Email validation with detailed rules
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    value = value.trim();

    // Email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      if (!value.contains('@')) {
        return 'Email must contain @ symbol';
      }
      if (!value.contains('.')) {
        return 'Email must contain domain (e.g., .com, .org)';
      }
      return 'Please enter a valid email address';
    }

    // Check for consecutive dots
    if (value.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }

    // Check local part length
    final localPart = value.split('@')[0];
    if (localPart.length > 64) {
      return 'Email local part is too long';
    }

    // Check total length
    if (value.length > 254) {
      return 'Email address is too long';
    }

    return null;
  }

  // Password validation with strength check
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 100) {
      return 'Password must be less than 100 characters';
    }

    // Check for spaces
    if (value.contains(' ')) {
      return 'Password cannot contain spaces';
    }

    // Optional: Strong password validation
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    List<String> missingRequirements = [];
    if (!hasUppercase) missingRequirements.add('uppercase letter');
    if (!hasLowercase) missingRequirements.add('lowercase letter');
    if (!hasDigits) missingRequirements.add('number');
    if (!hasSpecialChars) missingRequirements.add('special character');

    if (missingRequirements.isNotEmpty) {
      return 'Password should contain at least one ${missingRequirements.join(", ")}';
    }

    return null;
  }

  // Confirm password validation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Terms acceptance validation
  String? _validateTerms(bool? value) {
    if (value != true) {
      return 'You must accept the Terms and Conditions';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate() && _acceptedTerms) {
      // Close keyboard
      FocusScope.of(context).unfocus();

      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authVm.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Conditions'),
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Password strength indicator
  Widget _buildPasswordStrengthIndicator(String password) {
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color color;
    String text;
    if (strength <= 1) {
      color = Colors.red;
      text = 'Weak';
    } else if (strength <= 2) {
      color = Colors.orange;
      text = 'Fair';
    } else if (strength <= 3) {
      color = Colors.blue;
      text = 'Good';
    } else {
      color = Colors.green;
      text = 'Strong';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: strength / 4,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context, listen: true);
    final isLoading = authVm.isLoading;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name Field
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person_outline, size: 20),
              helperText: 'Enter your full name as you want it displayed',
              helperStyle: TextStyle(fontSize: 12, color: Color(0xFF6B6A65)),
            ),
            validator: _validateName,
            onFieldSubmitted: (_) {
              _emailFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'hello@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
              helperText: 'We\'ll never share your email',
              helperStyle: TextStyle(fontSize: 12, color: Color(0xFF6B6A65)),
            ),
            validator: _validateEmail,
            onFieldSubmitted: (_) {
              _passwordFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            textInputAction: TextInputAction.next,
            obscureText: _obscurePassword,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              helperText: 'At least 6 characters with uppercase, lowercase, number, and special character',
              helperStyle: const TextStyle(fontSize: 12, color: Color(0xFF6B6A65)),
            ),
            validator: _validatePassword,
            onChanged: (value) {
              setState(() {}); // Trigger strength indicator rebuild
            },
            onFieldSubmitted: (_) {
              _confirmPasswordFocusNode.requestFocus();
            },
          ),
          _buildPasswordStrengthIndicator(_passwordController.text),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            textInputAction: TextInputAction.done,
            obscureText: _obscureConfirmPassword,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 16),

          // Terms and Conditions
          FormField<bool>(
            validator: _validateTerms,
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: isLoading ? null : (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                              field.didChange(_acceptedTerms);
                            });
                          },
                          activeColor: const Color(0xFFC5A028),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptedTerms = !_acceptedTerms;
                              field.didChange(_acceptedTerms);
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF2C2C2C),
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    color: Color(0xFFC5A028),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: Color(0xFFC5A028),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 4),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Register Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A028),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Create Account'),
            ),
          ),

          // Error message from ViewModel
          if (authVm.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: Colors.red.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      authVm.error!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}