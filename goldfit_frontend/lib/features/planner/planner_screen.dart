import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/features/planner/planner_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

/// Planner screen displaying calendar view for outfit planning
/// Shows week/month toggle, calendar widget, and outfit assignment interface
/// 
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 14.3, 14.4
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
    
    // Load initial data from ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<PlannerViewModel>();
      viewModel.loadOutfits();
      
      // Load calendar for current month
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      viewModel.loadCalendar(startOfMonth, endOfMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final viewModel = Provider.of<PlannerViewModel>(context);
    final calendarView = appState.calendarView;

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
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: GoldFitTheme.textMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.error!,
                        style: TextStyle(
                          fontSize: 14,
                          color: GoldFitTheme.textMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          viewModel.loadOutfits();
                          final now = DateTime.now();
                          final startOfMonth = DateTime(now.year, now.month, 1);
                          final endOfMonth = DateTime(now.year, now.month + 1, 0);
                          viewModel.loadCalendar(startOfMonth, endOfMonth);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
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
                  
                  // Load calendar data for the new month when page changes
                  final startOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
                  final endOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
                  context.read<PlannerViewModel>().loadCalendar(startOfMonth, endOfMonth);
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
                    final outfit = viewModel.hasAnyOutfitForDate(date) ? true : false;
                    if (outfit) {
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
          
          // Selected date outfit display
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_formatSelectedDate(_selectedDay), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GoldFitTheme.textDark)),
                    const SizedBox(height: 16),
                    _buildMorningCard(context, viewModel),
                    const SizedBox(height: 16),
                    _buildAfternoonCard(context, viewModel),
                    const SizedBox(height: 16),
                    _buildEveningCard(context, viewModel),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, viewModel),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotCard(BuildContext context, PlannerViewModel viewModel, String title, String timeSlot) {
    return Container(
      decoration: BoxDecoration(
        color: GoldFitTheme.backgroundLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GoldFitTheme.yellow200, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: GoldFitTheme.textMedium),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: GoldFitTheme.textMedium)),
            ],
          ),
          GestureDetector(
            onTap: () => _showOutfitPicker(context, viewModel, timeSlot),
            child: Text('Assign', style: TextStyle(fontSize: 12, color: GoldFitTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMorningCard(BuildContext context, PlannerViewModel viewModel) {
    final outfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'morning');
    if (outfit == null) return _buildEmptySlotCard(context, viewModel, 'Morning', 'morning');

    return Container(
      decoration: BoxDecoration(
        color: GoldFitTheme.yellow100,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Morning', style: TextStyle(fontWeight: FontWeight.bold, color: GoldFitTheme.textMedium)),
              GestureDetector(
                onTap: () => _showOutfitPicker(context, viewModel, 'morning'),
                child: Text('Edit', style: TextStyle(fontSize: 12, color: GoldFitTheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showOutfitDetails(context, outfit),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    height: 100,
                    color: Colors.white,
                    child: outfit.modelImagePath != null 
                      ? LocalImageWidget(imagePath: outfit.modelImagePath!, width: 80, height: 100, fit: BoxFit.cover)
                      : const Icon(Icons.checkroom, color: GoldFitTheme.gold600, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(outfit.eventName ?? outfit.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'manrope', color: GoldFitTheme.textDark)),
                      const SizedBox(height: 4),
                      Text(outfit.startTime ?? '9:00 AM', style: TextStyle(color: GoldFitTheme.textMedium)),
                      const SizedBox(height: 8),
                      if (outfit.vibe != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: GoldFitTheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(outfit.vibe!, style: TextStyle(fontSize: 10, color: GoldFitTheme.primary, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAfternoonCard(BuildContext context, PlannerViewModel viewModel) {
    final outfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'afternoon');
    if (outfit == null) return _buildEmptySlotCard(context, viewModel, 'Afternoon', 'afternoon');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Afternoon', style: TextStyle(fontWeight: FontWeight.bold, color: GoldFitTheme.textMedium)),
              GestureDetector(
                onTap: () => _showOutfitPicker(context, viewModel, 'afternoon'),
                child: Text('Edit', style: TextStyle(fontSize: 12, color: GoldFitTheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showOutfitDetails(context, outfit),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GoldFitTheme.yellow200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Row(
              children: [
                 Icon(Icons.shopping_bag_outlined, color: GoldFitTheme.primary),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(outfit.eventName ?? outfit.name, style: TextStyle(fontWeight: FontWeight.bold, color: GoldFitTheme.textDark)),
                 ),
                 Icon(Icons.arrow_forward_ios, size: 16, color: GoldFitTheme.textLight),
              ],
            )
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _showOutfitPicker(context, viewModel, 'afternoon'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: GoldFitTheme.primary, width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(vertical: 16)
          ),
          child: Text('COMPLETE AFTERNOON LOOK', style: TextStyle(color: GoldFitTheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildEveningCard(BuildContext context, PlannerViewModel viewModel) {
    final outfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'evening');
    if (outfit != null) {
      return Container(
        decoration: BoxDecoration(color: GoldFitTheme.yellow100, borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Evening', style: TextStyle(fontWeight: FontWeight.bold, color: GoldFitTheme.textMedium)),
                GestureDetector(
                  onTap: () => _showOutfitPicker(context, viewModel, 'evening'),
                  child: Text('Edit', style: TextStyle(fontSize: 12, color: GoldFitTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showOutfitDetails(context, outfit),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 80, height: 100, color: Colors.white,
                      child: outfit.modelImagePath != null 
                        ? LocalImageWidget(imagePath: outfit.modelImagePath!, width: 80, height: 100, fit: BoxFit.cover)
                        : const Icon(Icons.checkroom, color: GoldFitTheme.gold600, size: 40),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(outfit.eventName ?? outfit.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'manrope', color: GoldFitTheme.textDark)),
                        const SizedBox(height: 4),
                        Text(outfit.startTime ?? '7:00 PM', style: TextStyle(color: GoldFitTheme.textMedium)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        )
      );
    }
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: GoldFitTheme.textDark,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [GoldFitTheme.textDark.withOpacity(0.9), GoldFitTheme.gold600.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      ),
      child: Center(
        child: ElevatedButton(
          onPressed: () => _showOutfitPicker(context, viewModel, 'evening'),
          style: ElevatedButton.styleFrom(
             backgroundColor: Colors.white,
             foregroundColor: Colors.black,
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('SELECT OUTFIT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
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

  Widget _buildActionButtons(BuildContext context, PlannerViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleCloneDay(context, viewModel),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Clone Day', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: GoldFitTheme.primary,
              side: const BorderSide(color: GoldFitTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleAddToCalendar(context, viewModel),
            icon: const Icon(Icons.calendar_month, size: 18),
            label: const Text('Add to Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: GoldFitTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _handleCloneDay(BuildContext context, PlannerViewModel viewModel) async {
    if (!viewModel.hasAnyOutfitForDate(_selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No outfits to clone on this date')),
      );
      return;
    }

    final targetDate = await showDatePicker(
      context: context,
      initialDate: _selectedDay.add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (targetDate != null && context.mounted) {
      await viewModel.cloneDay(_selectedDay, targetDate);
      if (viewModel.error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.error!)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Day cloned to ${_formatSelectedDate(targetDate)}')),
        );
      }
    }
  }

  void _handleAddToCalendar(BuildContext context, PlannerViewModel viewModel) {
    if (!viewModel.hasAnyOutfitForDate(_selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No outfits to add to calendar')),
      );
      return;
    }
    
    final morningOutfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'morning');
    final afternoonOutfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'afternoon');
    final eveningOutfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'evening');
    
    void addEvent(Outfit outfit, int hour) {
        final Event event = Event(
          title: outfit.eventName ?? 'GoldFit - ${outfit.name}',
          description: 'Wearing: ${outfit.name}',
          location: '',
          startDate: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour, 0),
          endDate: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour + 2, 0),
          allDay: false,
        );
        Add2Calendar.addEvent2Cal(event);
    }
    
    if (morningOutfit != null) addEvent(morningOutfit, 9);  // 9 AM
    if (afternoonOutfit != null) addEvent(afternoonOutfit, 13); // 1 PM
    if (eveningOutfit != null) addEvent(eveningOutfit, 19); // 7 PM
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening calendar app...')),
    );
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

  void _showOutfitPicker(BuildContext context, PlannerViewModel viewModel, String timeSlot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final outfits = viewModel.outfits;
          
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
                                onTap: () async {
                                  await viewModel.assignOutfit(outfit.id, _selectedDay, timeSlot);
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    
                                    if (viewModel.error != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(viewModel.error!),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Outfit assigned to ${_formatSelectedDate(_selectedDay)}'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
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

