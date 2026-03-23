import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsSwitchWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool initialValue;
  final Color iconColor;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitchWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.iconColor,
    this.onChanged,
  });

  @override
  State<SettingsSwitchWidget> createState() => _SettingsSwitchWidgetState();
}

class _SettingsSwitchWidgetState extends State<SettingsSwitchWidget> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: widget.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
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
              value: _value,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF13EC80),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade300,
              onChanged: (val) {
                setState(() {
                  _value = val;
                });
                widget.onChanged?.call(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
