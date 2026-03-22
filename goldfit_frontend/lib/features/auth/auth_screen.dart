import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/auth/auth_viewmodel.dart';
import 'package:goldfit_frontend/features/auth/widgets/login_form.dart';
import 'package:goldfit_frontend/features/auth/widgets/register_form.dart';
import 'package:goldfit_frontend/features/auth/widgets/google_sign_in_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    // Check auth state on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      authVm.checkAuthState();
    });
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context, listen: true);

    // If authenticated, navigate to home
    if (authVm.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFC5A028),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrandSection(),
                const SizedBox(height: 32),

                if (authVm.error != null) _buildErrorMessage(authVm.error!),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(48),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: _isLogin
                      ? const LoginForm()
                      : const RegisterForm(),
                ),
                const SizedBox(height: 24),
                const GoogleSignInButton(),
                const SizedBox(height: 24),
                _buildToggleModeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFC5A028).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 40,
            color: Color(0xFFC5A028),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Welcome Back' : 'Create Account',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to continue your journey'
              : 'Get started with GoldFit',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Color(0xFF6B6A65),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleModeButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF6B6A65),
          ),
        ),
        TextButton(
          onPressed: _toggleMode,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Color(0xFFC5A028),
            ),
          ),
        ),
      ],
    );
  }
}