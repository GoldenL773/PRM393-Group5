import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/utils/theme_background.dart';

class SettingsDarkModeWidget extends StatelessWidget {
  const SettingsDarkModeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeBackgroundApp>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dark_mode_outlined,
                color: Color(0xFF6B5B95),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dark Mode",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Switch dark interface",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              activeColor: const Color(0xFF13EC80),
              activeTrackColor: const Color(0xFF13EC80).withOpacity(0.5),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade300,
              onChanged: (val) {
                themeProvider.setTheme(
                  val ? ThemeModeType.dark : ThemeModeType.light,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
