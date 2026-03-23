import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/features/auth/auth_viewmodel.dart';
import 'package:goldfit_frontend/features/auth/models/user_model.dart';

import 'package:goldfit_frontend/features/wardrobe/wardrobe_viewmodel.dart';
import 'package:goldfit_frontend/features/favorites/favorites_viewmodel.dart';
import 'package:goldfit_frontend/features/planner/planner_viewmodel.dart';

import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when profile is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeViewModel>().loadItems();
      context.read<FavoritesViewModel>().loadFavorites();
      context.read<PlannerViewModel>().loadOutfits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context, listen: true);
    final user = authVm.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF7),
      // Trong AppBar, thêm nút edit
      appBar: AppBar(
        title: const Text(
          'Profile',
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            child: const Text(
              'Edit',
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
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(user),
            const SizedBox(height: 24),

            // Stats Section
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Menu Items
            _buildMenuItems(context),
            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(context, authVm),
            const SizedBox(height: 40),

            // App Version
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC5A028).withOpacity(0.1),
              image: user?.photoUrl != null
                  ? DecorationImage(
                image: NetworkImage(user!.photoUrl!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: user?.photoUrl == null
                ? Icon(
              Icons.person,
              size: 50,
              color: const Color(0xFFC5A028),
            )
                : null,
          ),
          const SizedBox(height: 16),

          // User Name
          Text(
            user?.displayName ?? 'User',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),

          // User Email
          Text(
            user?.email ?? 'No email',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF6B6A65),
            ),
          ),
          const SizedBox(height: 12),

          // Auth Provider Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A028).withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              user?.provider == AuthProvider.google
                  ? 'Connected with Google'
                  : 'Email Account',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: const Color(0xFFC5A028),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Consumer3<WardrobeViewModel, FavoritesViewModel, PlannerViewModel>(
      builder: (context, wardrobeVm, favoritesVm, plannerVm, child) {
        final itemsCount = wardrobeVm.items.length;
        final outfitsCount = plannerVm.outfits.length;
        final favoritesCount = favoritesVm.favoriteOutfits.length + favoritesVm.favoriteClothes.length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.checkroom,
                value: '$itemsCount',
                label: 'Items',
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE6E1D6),
              ),
              _buildStatItem(
                icon: Icons.style,
                value: '$outfitsCount',
                label: 'Outfits',
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE6E1D6),
              ),
              _buildStatItem(
                icon: Icons.favorite,
                value: '$favoritesCount',
                label: 'Favorites',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFC5A028), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF6B6A65),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.shopping_bag_outlined,
        'title': 'My Wardrobe',
        'subtitle': 'View and manage your clothing items',
        'onTap': () {
          Navigator.pushNamed(context, '/wardrobe');
        },
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Planner',
        'subtitle': 'Plan your outfits for the week',
        'onTap': () {
          Navigator.pushNamed(context, '/planner');
        },
      },
      {
        'icon': Icons.insights_outlined,
        'title': 'Insights',
        'subtitle': 'View your fashion analytics',
        'onTap': () {
          Navigator.pushNamed(context, '/insights');
        },
      },
      {
        'icon': Icons.favorite_border,
        'title': 'Favorites',
        'subtitle': 'Your saved outfits and items',
        'onTap': () {
          Navigator.pushNamed(context, '/favorites');
        },
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Settings',
        'subtitle': 'App preferences and account settings',
        'onTap': () {
          _showComingSoon(context);
        },
      },
      {
        'icon': Icons.help_outline,
        'title': 'Help & Support',
        'subtitle': 'FAQs and contact support',
        'onTap': () {
          _showComingSoon(context);
        },
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < menuItems.length; i++)
            Column(
              children: [
                ListTile(
                  leading: Icon(
                    menuItems[i]['icon'] as IconData,
                    color: const Color(0xFFC5A028),
                    size: 24,
                  ),
                  title: Text(
                    menuItems[i]['title'] as String,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  subtitle: Text(
                    menuItems[i]['subtitle'] as String,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF6B6A65),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFC5A028),
                  ),
                  onTap: menuItems[i]['onTap'] as VoidCallback,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                if (i < menuItems.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: const Color(0xFFE6E1D6),
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthViewModel authVm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context, authVm),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide(color: Colors.red.shade200),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 8),
            const Text('Sign Out'),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'Version 1.0.0',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: Color(0xFF9E9A92),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel authVm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF6B6A65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF6B6A65),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFC5A028),
                  ),
                ),
              );

              await authVm.signOut();

              if (context.mounted) {
                Navigator.pop(context); // Close loading
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        backgroundColor: Color(0xFFC5A028),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}