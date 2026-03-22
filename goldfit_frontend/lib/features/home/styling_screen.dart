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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: GoldFitTheme.textDark,
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
            Text(
              'Describe your event',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: GoldFitTheme.textDark,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eventController,
              decoration: const InputDecoration(
                hintText: 'e.g., "Brunch with friends" or "Job interview"',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleTextSubmit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleTextSubmit,
                child: const Text('Get Recommendations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vibe card widget for predefined vibe options
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
    return Card(
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? GoldFitTheme.primary : const Color(0xFFF1F5F9),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GoldFitTheme.yellow100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: GoldFitTheme.gold600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: GoldFitTheme.textDark,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: GoldFitTheme.textMedium,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: isSelected ? GoldFitTheme.gold600 : GoldFitTheme.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
