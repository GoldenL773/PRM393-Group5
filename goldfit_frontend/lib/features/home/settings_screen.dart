import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
                      _buildProfile(),
                      const SizedBox(height: 24),
                      _sectionTitle("ACCOUNT", const Color(0xFF13E819)),
                      const SizedBox(height: 8),
                      _buildItem(Icons.email_outlined, "Email", "alex@goldfit.com", const Color(0xFF13EC80)),
                      _buildItem(Icons.lock_outline, "Password", "Last changed 3 months ago", const Color(0xFF13EC80)),
                      _buildItem(Icons.privacy_tip_outlined, "Privacy", "Profile visibility & data", const Color(0xFF13EC80)),
                      const SizedBox(height: 20),
                      _sectionTitle("NOTIFICATIONS", const Color(0xFFFF9800)),
                      const SizedBox(height: 8),
                      _buildSwitch(Icons.lightbulb_outline, "Daily Suggestions", "Workout tips and nutrition", true, const Color(0xFFFF9800)),
                      _buildSwitch(Icons.notifications_outlined, "Planner Reminders", "Stay on track with your goals", true, const Color(0xFFFF9800)),
                      const SizedBox(height: 20),
                      _sectionTitle("APP SETTINGS", const Color(0xFFFF9800)),
                      const SizedBox(height: 8),
                      _buildItem(Icons.language_outlined, "Language", "English (US)", const Color(0xFF3F51B5)),
                      _buildSwitch(Icons.dark_mode_outlined, "Dark Mode", "Switch dark interface", false, const Color(0xFF6B5B95)),
                      const SizedBox(height: 20),
                      _sectionTitle("SUPPORT", const Color(0xFFFF9800)),
                      const SizedBox(height: 8),
                      _buildItem(Icons.help_outline, "Help Center", "FAQs and tutorials", const Color(0xFF3F51B5)),
                      _buildItem(Icons.contact_mail_outlined, "Contact Us", "Get in touch with our team", const Color(0xFF9E9E9E)),
                      const SizedBox(height: 24),
                      _logoutButton(),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "GoldFit Version 2.4.1",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfile() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF9800),
                Color(0xFFFFD54F),
              ],
            ),
          ),
          child: const Icon(
            Icons.person_off_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Alex Johnson",
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Pro Member since 2023",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, String subtitle, Color iconColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15), // nền nhạt
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor, // icon đậm
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  Widget _customSwitch(bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 50,
        height: 28,
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? Color(0xFF13EC80) : Colors.grey.shade300,
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(IconData icon, String title, String subtitle, bool initialValue, Color iconColor) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool value = initialValue;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        )),
                  ],
                ),
              ),

              // 🔥 dùng custom switch
              _customSwitch(value, (val) {
                setState(() {
                  value = val;
                });
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _logoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade300,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Logout",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
