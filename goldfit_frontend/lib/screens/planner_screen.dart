import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/app_state.dart';
import '../models/outfit.dart';
import '../utils/theme.dart';

/// Planner screen displaying calendar view for outfit planning
/// Shows week/month toggle, calendar widget, and outfit assignment interface
/// 
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final calendarView = appState.calendarView;
    final assignedOutfit = appState.getOutfitForDate(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        actions: [
          // View toggle buttons
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                _ViewToggleButton(
                  label: 'Week',
                  isActive: calendarView == CalendarView.week,
                  onTap: () => appState.setCalendarView(CalendarView.week),
                ),
                const SizedBox(width: 8),
                _ViewToggleButton(
                  label: 'Month',
                  isActive: calendarView == CalendarView.month,
                  onTap: () => appState.setCalendarView(CalendarView.month),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar widget using table_calendar
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: TableCalendar(
                key: ValueKey(calendarView),
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: calendarView == CalendarView.month
                    ? CalendarFormat.month
                    : CalendarFormat.week,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  appState.selectDate(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: GoldFitTheme.yellow200,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: GoldFitTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: GoldFitTheme.gold600,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GoldFitTheme.textDark,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final outfit = appState.getOutfitForDate(date);
                    if (outfit != null) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: GoldFitTheme.gold600,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          
          // Selected date outfit display and assign button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _formatSelectedDate(_selectedDay),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GoldFitTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (assignedOutfit != null) ...[
                  // Display assigned outfit
                  _OutfitDisplay(
                    outfit: assignedOutfit,
                    onTap: () => _showOutfitDetails(context, assignedOutfit),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showOutfitPicker(context, appState),
                    child: const Text('Change Outfit'),
                  ),
                ] else ...[
                  // No outfit assigned
                  Text(
                    'No outfit assigned for this date',
                    style: TextStyle(
                      fontSize: 14,
                      color: GoldFitTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showOutfitPicker(context, appState),
                    child: const Text('Assign Outfit'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showOutfitDetails(BuildContext context, Outfit outfit) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              outfit.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GoldFitTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            if (outfit.vibe != null)
              Text(
                'Vibe: ${outfit.vibe}',
                style: TextStyle(
                  fontSize: 14,
                  color: GoldFitTheme.textMedium,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to try-on screen with this outfit
                Navigator.pushNamed(
                  context,
                  '/try-on',
                  arguments: outfit,
                );
              },
              child: const Text('View in Try-On'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOutfitPicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final outfits = appState.allOutfits;
          
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select an Outfit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GoldFitTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: outfits.isEmpty
                      ? Center(
                          child: Text(
                            'No saved outfits yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: GoldFitTheme.textMedium,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: outfits.length,
                          itemBuilder: (context, index) {
                            final outfit = outfits[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(outfit.name),
                                subtitle: outfit.vibe != null
                                    ? Text('Vibe: ${outfit.vibe}')
                                    : null,
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: GoldFitTheme.textLight,
                                ),
                                onTap: () {
                                  appState.assignOutfitToDate(outfit.id, _selectedDay);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Outfit assigned to ${_formatSelectedDate(_selectedDay)}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// View toggle button widget for Week/Month selection
class _ViewToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? GoldFitTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? GoldFitTheme.primary : GoldFitTheme.textLight,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? GoldFitTheme.textDark : GoldFitTheme.textMedium,
          ),
        ),
      ),
    );
  }
}

/// Widget to display assigned outfit
class _OutfitDisplay extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback onTap;

  const _OutfitDisplay({
    required this.outfit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GoldFitTheme.yellow100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GoldFitTheme.yellow200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.checkroom,
              color: GoldFitTheme.gold600,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GoldFitTheme.textDark,
                    ),
                  ),
                  if (outfit.vibe != null)
                    Text(
                      outfit.vibe!,
                      style: TextStyle(
                        fontSize: 12,
                        color: GoldFitTheme.textMedium,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GoldFitTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
