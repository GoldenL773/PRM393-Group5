import 'package:flutter/material.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/shared/utils/navigation_manager.dart';

/// Styling input screen for selecting vibe or describing event
/// Shows predefined vibe cards and text input for custom event descriptions
class StylingScreen extends StatefulWidget {
  const StylingScreen({super.key});

  @override
  State<StylingScreen> createState() => _StylingScreenState();
}

class _StylingScreenState extends State<StylingScreen> {
  final TextEditingController _eventController = TextEditingController();
  final NavigationManager _navigationManager = NavigationManager();
  String? _selectedVibe;

  final List<Map<String, dynamic>> _vibes = [
    {
      'name': 'Casual',
      'icon': Icons.weekend,
      'description': 'Relaxed and comfortable',
    },
    {
      'name': 'Work',
      'icon': Icons.work_outline,
      'description': 'Professional and polished',
    },
    {
      'name': 'Date Night',
      'icon': Icons.favorite_outline,
      'description': 'Stylish and romantic',
    },
  ];

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  void _handleVibeSelection(String vibe) {
    setState(() {
      _selectedVibe = vibe;
    });
    // Navigate to recommendations with selected vibe
    _navigationManager.navigateToRecommendations(
      context,
      vibe: vibe,
    );
  }

  void _handleTextSubmit() {
    final text = _eventController.text.trim();
    if (text.isNotEmpty) {
      // Navigate to recommendations with event description
      _navigationManager.navigateToRecommendations(
        context,
        eventDescription: text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Styled'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'What\'s the vibe today?',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: GoldFitTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),

            // Vibe cards
            ...(_vibes.map((vibe) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _VibeCard(
                    name: vibe['name'] as String,
                    icon: vibe['icon'] as IconData,
                    description: vibe['description'] as String,
                    isSelected: _selectedVibe == vibe['name'],
                    onTap: () => _handleVibeSelection(vibe['name'] as String),
                  ),
                ))),

            const SizedBox(height: 32),

            // Divider with "OR"
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: GoldFitTheme.textMedium,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 32),

            // Custom event description
            const Text(
              'Describe your event',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: GoldFitTheme.textDark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: GoldFitTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GoldFitTheme.yellow100, width: 1.5),
              ),
              child: TextField(
                controller: _eventController,
                style: const TextStyle(fontSize: 16, color: GoldFitTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'e.g., "Brunch with friends" or "Job interview"',
                  hintStyle: TextStyle(color: GoldFitTheme.textLight.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleTextSubmit(),
              ),
            ),
            const SizedBox(height: 32),
            
            // Get Recommendations button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [GoldFitTheme.primary, GoldFitTheme.yellow200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GoldFitTheme.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _handleTextSubmit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Get Recommendations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vibe card widgets for predefined vibe options
class _VibeCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _VibeCard({
    required this.name,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? GoldFitTheme.gold600 : GoldFitTheme.yellow100.withOpacity(0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? GoldFitTheme.gold600.withOpacity(0.15) : Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GoldFitTheme.yellow200.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: GoldFitTheme.gold600,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: GoldFitTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: GoldFitTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: isSelected ? GoldFitTheme.gold600 : GoldFitTheme.textLight.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
