import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsProfileWidget extends StatelessWidget {
  final String userName;

  const SettingsProfileWidget({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFFD54F)],
            ),
          ),
          child: const Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          userName,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Pro Member since 2023",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
