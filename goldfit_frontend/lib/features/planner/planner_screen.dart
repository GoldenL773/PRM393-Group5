import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';
import 'package:goldfit_frontend/shared/utils/theme.dart';
import 'package:goldfit_frontend/features/planner/planner_viewmodel.dart';
import 'package:goldfit_frontend/shared/widgets/local_image_widget.dart';
import 'package:intl/intl.dart';

/// Planner screen displaying calendar view for outfit planning
/// Shows week/month toggle, calendar widgets, and outfit assignment interface
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
      backgroundColor: GoldFitTheme.backgroundDark, // Uses the creamy off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          DateFormat('MMMM').format(_focusedDay),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: GoldFitTheme.textDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => appState.toggleCalendarView(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GoldFitTheme.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GoldFitTheme.yellow200.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: GoldFitTheme.gold600,
                ),
              ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: TableCalendar(
                      key: ValueKey(calendarView),
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      calendarFormat: calendarView == CalendarView.month
                          ? CalendarFormat.month
                          : CalendarFormat.week,
                      daysOfWeekVisible: false,
                      rowHeight: 85, // Taller rows to fit custom pill
                      headerVisible:
                          false, // Hidden header (using custom appbar title)
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
                        final startOfMonth = DateTime(
                          focusedDay.year,
                          focusedDay.month,
                          1,
                        );
                        final endOfMonth = DateTime(
                          focusedDay.year,
                          focusedDay.month + 1,
                          0,
                        );
                        context.read<PlannerViewModel>().loadCalendar(
                          startOfMonth,
                          endOfMonth,
                        );
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, date, _) =>
                            _buildDateCell(date, false, viewModel),
                        selectedBuilder: (context, date, _) =>
                            _buildDateCell(date, true, viewModel),
                        todayBuilder: (context, date, _) => _buildDateCell(
                          date,
                          isSameDay(date, _selectedDay),
                          viewModel,
                        ),
                        outsideBuilder: (context, date, _) => _buildDateCell(
                          date,
                          false,
                          viewModel,
                          isOutside: true,
                        ),
                      ),
                    ),
                  ),
                ),

                // Daily Event Note Section
                _buildDailyNoteSection(context, viewModel),

                // Selected date outfit display
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
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

  Widget _buildDateCell(
    DateTime date,
    bool isSelected,
    PlannerViewModel viewModel, {
    bool isOutside = false,
  }) {
    final dayStr = DateFormat('E').format(date).toUpperCase();
    final dateStr = date.day.toString();
    final hasEvent =
        viewModel.hasAnyOutfitForDate(date) ||
        (viewModel.getNoteForDate(date)?.isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFAC8442)
            : (isOutside
                  ? Colors.transparent
                  : GoldFitTheme.backgroundDark.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayStr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : (isOutside
                        ? GoldFitTheme.textLight
                        : GoldFitTheme.textMedium),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isOutside
                        ? GoldFitTheme.textLight
                        : GoldFitTheme.textDark),
            ),
          ),
          if (hasEvent || isSelected) ...[
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : GoldFitTheme.gold600,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyNoteSection(
    BuildContext context,
    PlannerViewModel viewModel,
  ) {
    final note = viewModel.getNoteForDate(_selectedDay) ?? '';
    final controller = TextEditingController(text: note);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: GoldFitTheme.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'Add an event note for today (e.g. Executive Meeting)',
          hintStyle: TextStyle(color: GoldFitTheme.textLight, fontSize: 12),
          prefixIcon: const Icon(
            Icons.event_note,
            color: Color(0xFFAC8442),
            size: 18,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: GoldFitTheme.yellow100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFAC8442)),
          ),
        ),
        onSubmitted: (value) => viewModel.saveNoteForDate(_selectedDay, value),
      ),
    );
  }

  Widget _buildEmptySlotCard(
    BuildContext context,
    PlannerViewModel viewModel,
    String title,
    String timeSlot,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: GoldFitTheme.backgroundLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: GoldFitTheme.yellow200.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: GoldFitTheme.textMedium),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: GoldFitTheme.textMedium,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _showOutfitPicker(context, viewModel, timeSlot),
            child: Text(
              'Add Details',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFAC8442),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onAction,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: GoldFitTheme.textDark,
              letterSpacing: 1.2,
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFAC8442),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Morning Card (Premium UI Redesign)
  Widget _buildMorningCard(BuildContext context, PlannerViewModel viewModel) {
    final outfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'morning');
    if (outfit == null)
      return _buildEmptySlotCard(context, viewModel, 'Morning', 'morning');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          'Morning',
          'Edit',
          () => _showOutfitPicker(context, viewModel, 'morning'),
        ),
        GestureDetector(
          onTap: () => _showOutfitDetails(context, outfit),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(24),
                    ),
                  ),
                  child: outfit.modelImagePath != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(24),
                          ),
                          child: LocalImageWidget(
                            imagePath: outfit.modelImagePath!,
                            width: 120,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.checkroom,
                            color: GoldFitTheme.primary,
                            size: 40,
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outfit.eventName ?? outfit.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: GoldFitTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          outfit.vibe ?? 'Carefully curated look.',
                          style: TextStyle(
                            fontSize: 12,
                            color: GoldFitTheme.textMedium,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (outfit.vibe != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: GoldFitTheme.backgroundDark,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'BUSINESS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: GoldFitTheme.textDark,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: GoldFitTheme.backgroundDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                outfit.startTime ?? '9:00 AM',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: GoldFitTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAfternoonCard(BuildContext context, PlannerViewModel viewModel) {
    final outfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'afternoon');
    if (outfit == null)
      return _buildEmptySlotCard(context, viewModel, 'Afternoon', 'afternoon');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          'Afternoon',
          'Add Details',
          () => _showOutfitPicker(context, viewModel, 'afternoon'),
        ),
        GestureDetector(
          onTap: () => _showOutfitDetails(context, outfit),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (outfit.modelImagePath != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: LocalImageWidget(
                              imagePath: outfit.modelImagePath!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      else
                        const Expanded(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: GoldFitTheme.primary,
                            size: 40,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'PRIMARY OUTFIT',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: GoldFitTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Icon(
                          Icons.category,
                          color: GoldFitTheme.textLight,
                          size: 40,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'ACCESSORIES',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: GoldFitTheme.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showOutfitPicker(context, viewModel, 'afternoon'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFDEDACA), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle,
                  color: Color(0xFF8B6C31),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'COMPLETE AFTERNOON LOOK',
                  style: TextStyle(
                    color: GoldFitTheme.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEveningCard(BuildContext context, PlannerViewModel viewModel) {
    final outfit = viewModel.getOutfitForDateAndTime(_selectedDay, 'evening');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Evening', '', () {}),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: GoldFitTheme.backgroundDark,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (outfit?.modelImagePath != null)
                  Opacity(
                    opacity: 0.8,
                    child: LocalImageWidget(
                      imagePath: outfit!.modelImagePath!,
                      fit: BoxFit.cover,
                    ),
                  ),
                Container(
                  color: Colors.white.withOpacity(0.7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEDACA).withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_bar,
                          color: Color(0xFF5B4926),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        outfit?.eventName ?? 'Night',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: GoldFitTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select a curated evening look\nfor the event.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: GoldFitTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            _showOutfitPicker(context, viewModel, 'evening'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B6C31),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          outfit != null ? 'CHANGE OUTFIT' : 'SELECT OUTFIT',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatSelectedDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildActionButtons(BuildContext context, PlannerViewModel viewModel) {
    return Row(
      children: [
        // Expanded(
        //   child: OutlinedButton.icon(
        //     onPressed: () => _handleAddToCalendar(context, viewModel),
        //     icon: const Icon(
        //       Icons.calendar_month,
        //       size: 16,
        //       color: GoldFitTheme.textDark,
        //     ),
        //     label: const Text(
        //       'ADD TO CALENDAR',
        //       style: TextStyle(
        //         fontWeight: FontWeight.w800,
        //         fontSize: 10,
        //         color: GoldFitTheme.textDark,
        //       ),
        //     ),
        //     style: OutlinedButton.styleFrom(
        //       backgroundColor: const Color(0xFFEBEBEB),
        //       side: BorderSide.none,
        //       padding: const EdgeInsets.symmetric(vertical: 16),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(30),
        //       ),
        //     ),
        //   ),
        // ),
        // const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleCloneDay(context, viewModel),
            icon: const Icon(
              Icons.copy,
              size: 16,
              color: GoldFitTheme.textDark,
            ),
            label: const Text(
              'CLONE DAY',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 10,
                color: GoldFitTheme.textDark,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEBEBEB),
              foregroundColor: GoldFitTheme.textDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(viewModel.error!)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Day cloned to ${_formatSelectedDate(targetDate)}'),
          ),
        );
      }
    }
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
                style: TextStyle(fontSize: 14, color: GoldFitTheme.textMedium),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to try-on screen with this outfit
                Navigator.pushNamed(context, '/try-on', arguments: outfit);
              },
              child: const Text('View in Try-On'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOutfitPicker(
    BuildContext context,
    PlannerViewModel viewModel,
    String timeSlot,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          // Refresh outfits to include newly created ones from Try-On
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              viewModel.loadOutfits();
            }
          });
          
          final outfits = viewModel.outfits;
          final appState = Provider.of<AppState>(context, listen: false);
          final items = appState.allItems;

          return Container(
            decoration: const BoxDecoration(
              color: GoldFitTheme.backgroundDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Text(
                      'Select for ${timeSlot.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: GoldFitTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    labelColor: GoldFitTheme.primary,
                    unselectedLabelColor: GoldFitTheme.textMedium,
                    indicatorColor: GoldFitTheme.primary,
                    tabs: [
                      Tab(text: 'Outfits'),
                      Tab(text: 'Items'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // OUTFITS TAB
                        outfits.isEmpty
                            ? const Center(
                                child: Text(
                                  'No saved outfits yet',
                                  style: TextStyle(
                                    color: GoldFitTheme.textMedium,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                key: const PageStorageKey('planner_outfits_list'),
                                controller: scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: outfits.length,
                                itemBuilder: (context, index) {
                                  final outfit = outfits[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: outfit.modelImagePath != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: LocalImageWidget(
                                                imagePath:
                                                    outfit.modelImagePath!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(Icons.checkroom),
                                      title: Text(outfit.name),
                                      subtitle: outfit.vibe != null
                                          ? Text('Vibe: ${outfit.vibe}')
                                          : null,
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: GoldFitTheme.textLight,
                                      ),
                                      onTap: () async {
                                        await viewModel.assignOutfit(
                                          outfit.id,
                                          _selectedDay,
                                          timeSlot,
                                        );
                                        if (context.mounted)
                                          Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              ),

                        // ITEMS TAB
                        items.isEmpty
                            ? const Center(
                                child: Text(
                                  'No items in wardrobe',
                                  style: TextStyle(
                                    color: GoldFitTheme.textMedium,
                                  ),
                                ),
                              )
                            : GridView.builder(
                                key: const PageStorageKey('planner_items_grid'),
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.8,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return GestureDetector(
                                    onTap: () async {
                                      await viewModel.assignSingleItemToDate(
                                        item,
                                        _selectedDay,
                                        timeSlot,
                                      );
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: GoldFitTheme.yellow200
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: LocalImageWidget(
                                          imagePath:
                                              item.cleanedImageUrl ??
                                              item.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// View toggle button widgets for Week/Month selection
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

