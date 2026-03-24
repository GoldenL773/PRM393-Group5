import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/auth/auth_viewmodel.dart';
import 'package:goldfit_frontend/features/home/settings_viewmodel.dart';
import 'package:goldfit_frontend/features/home/widgets/settings_profile_widget.dart';
import 'package:goldfit_frontend/features/home/widgets/settings_section_title.dart';
import 'package:goldfit_frontend/features/home/widgets/settings_item_widget.dart';
import 'package:goldfit_frontend/features/home/widgets/settings_switch_widget.dart';
import 'package:goldfit_frontend/features/home/widgets/settings_dark_mode_widget.dart';
import 'package:goldfit_frontend/features/home/widgets/settings_logout_button.dart';
import 'package:goldfit_frontend/features/home/widgets/update_email_dialog.dart';
import 'package:goldfit_frontend/features/home/widgets/update_password_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final settingsViewModel = SettingsViewModel(authViewModel);
    final currentUser = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SettingsProfileWidget(
              userName: currentUser?.displayName ?? "Guest User",
            ),
            const SizedBox(height: 24),
            
            const SettingsSectionTitle(
              title: "ACCOUNT",
              color: Color(0xFF13E819),
            ),
            const SizedBox(height: 8),
            SettingsItemWidget(
              icon: Icons.email_outlined,
              title: "Email",
              subtitle: currentUser?.email ?? "Not available",
              iconColor: const Color(0xFF13EC80),
              onTap: () => _showUpdateEmailDialog(context, settingsViewModel),
            ),
            SettingsItemWidget(
              icon: Icons.lock_outline,
              title: "Password",
              subtitle: "Tap to change password",
              iconColor: const Color(0xFF13EC80),
              onTap: () => _showUpdatePasswordDialog(context, settingsViewModel),
            ),
            const SettingsItemWidget(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy",
              subtitle: "Profile visibility & data",
              iconColor: Color(0xFF13EC80),
            ),
            
            const SizedBox(height: 20),
            
            const SettingsSectionTitle(
              title: "NOTIFICATIONS",
              color: Color(0xFFFF9800),
            ),
            const SizedBox(height: 8),
            const SettingsSwitchWidget(
              icon: Icons.lightbulb_outline,
              title: "Daily Suggestions",
              subtitle: "Workout tips and nutrition",
              initialValue: true,
              iconColor: Color(0xFFFF8800),
            ),
            const SettingsSwitchWidget(
              icon: Icons.notifications_outlined,
              title: "Planner Reminders",
              subtitle: "Stay on track with your goals",
              initialValue: true,
              iconColor: Color(0xFFFF9800),
            ),
            
            const SizedBox(height: 20),
            
            const SettingsSectionTitle(
              title: "APP SETTINGS",
              color: Color(0xFFFF9800),
            ),
            const SizedBox(height: 8),
            const SettingsItemWidget(
              icon: Icons.language_outlined,
              title: "Language",
              subtitle: "English (US)",
              iconColor: Color(0xFF3F51B5),
            ),
            const SettingsDarkModeWidget(),
            
            const SizedBox(height: 20),
            
            const SettingsSectionTitle(
              title: "SUPPORT",
              color: Color(0xFFFF9800),
            ),
            const SizedBox(height: 8),
            const SettingsItemWidget(
              icon: Icons.help_outline,
              title: "Help Center",
              subtitle: "FAQs and tutorials",
              iconColor: Color(0xFF3F51B5),
            ),
            const SettingsItemWidget(
              icon: Icons.contact_mail_outlined,
              title: "Contact Us",
              subtitle: "Get in touch with our team",
              iconColor: Color(0xFF9E9E9E),
            ),
            
            const SizedBox(height: 24),
            
            SettingsLogoutButton(
              onPressed: () => settingsViewModel.handleLogout(context),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: Text(
                "GoldFit Version 2.4.1",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateEmailDialog(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => UpdateEmailDialog(
        currentEmail: viewModel.authViewModel.currentUser?.email,
        onUpdate: (newEmail) {
          viewModel.handleUpdateEmail(context, newEmail);
        },
      ),
    );
  }

  void _showUpdatePasswordDialog(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => UpdatePasswordDialog(
        onUpdate: (currentPassword, newPassword, confirmPassword) {
          viewModel.handleUpdatePassword(
            context,
            currentPassword,
            newPassword,
            confirmPassword,
          );
        },
      ),
    );
  }
}
