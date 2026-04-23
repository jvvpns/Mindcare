import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/hilway_background.dart';
import '../../core/models/planner_entry.dart';
import '../providers/planner_provider.dart';
import '../../chatbot/providers/kelly_state_provider.dart';
import '../../shared/widgets/responsive_wrapper.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(plannerProvider);
    
    // Filter tasks for the selected day
    final selectedDayTasks = tasks.where((t) {
      if (_selectedDay == null) return false;
      return t.dueDate.year == _selectedDay!.year &&
             t.dueDate.month == _selectedDay!.month &&
             t.dueDate.day == _selectedDay!.day;
    }).toList();

    // Filter overdue tasks: include pending overdue AND completed overdue from last 7 days
    final overdue = tasks.where((t) {
      if (!t.dueDate.isBefore(DateTime.now().subtract(const Duration(hours: 1)))) return false;
      
      // If completed, only show if completed within the last 7 days (clipping infinite growth)
      if (t.isCompleted) {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        if (t.dueDate.isBefore(sevenDaysAgo)) return false;
      }

      // Exclude those already visible in the selected day's pending list to prevent duplicate widget keys
      if (_selectedDay != null && 
          t.dueDate.year == _selectedDay!.year &&
          t.dueDate.month == _selectedDay!.month &&
          t.dueDate.day == _selectedDay!.day) {
        return false;
      }
      return true;
    }).toList();
    
    // Split selected day tasks
    final todayPending = selectedDayTasks.where((t) => !t.isCompleted).toList();
    final todayDone = selectedDayTasks.where((t) => t.isCompleted).toList();
    final effectiveEmotion = ref.watch(globalBackgroundEmotionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Academic Planner', style: AppTextStyles.headingSmall),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.stethoscope, color: AppColors.primary),
            onPressed: () => context.push('/clinical-duty'),
          ),
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.week 
                  ? PhosphorIconsRegular.calendarBlank 
                  : PhosphorIconsRegular.calendarMinus,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.week 
                    ? CalendarFormat.month 
                    : CalendarFormat.week;
              });
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
        HapticFeedback.mediumImpact();
        _showAddTaskSheet(context, ref, _selectedDay);
      },
        backgroundColor: AppColors.primary,
        icon: const PhosphorIcon(PhosphorIconsRegular.plus, color: Colors.white),
        label: Text('Add Task', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
      ),
      body: HilwayBackground(
        emotion: effectiveEmotion,
        child: SafeArea(
          child: ResponsiveWrapper(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Calendar Header ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        // Remove horizontal padding so day columns have full width and won't clip
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TableCalendar(
                          firstDay: DateTime.now().subtract(const Duration(days: 365)),
                          lastDay: DateTime.now().add(const Duration(days: 365)),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.week: 'Week',
                          },
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!isSameDay(_selectedDay, selectedDay)) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            }
                          },
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          eventLoader: (day) {
                            return tasks.where((t) => isSameDay(t.dueDate, day)).toList();
                          },
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) return const SizedBox();
                              return Positioned(
                                bottom: 1,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: events.take(3).map((e) {
                                    final entry = e as PlannerEntry;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _TaskTile.getCategoryColor(entry.category),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            headerPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            titleTextStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                            leftChevronIcon: const PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 20),
                            rightChevronIcon: const PhosphorIcon(PhosphorIconsRegular.caretRight, size: 20),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            // Smaller font so all 7 labels (Sun-Sat) are always fully visible
                            weekdayStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            weekendStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            cellPadding: EdgeInsets.zero,
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            outsideDaysVisible: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
  
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
  
                // ── Task List for Selected Day ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isSameDay(_selectedDay, DateTime.now()) 
                            ? "Today's Tasks" 
                            : DateFormat('MMM d, yyyy').format(_selectedDay ?? DateTime.now()),
                          style: AppTextStyles.headingSmall,
                        ),
                        if (todayPending.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${todayPending.length} pending',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
  
                if (selectedDayTasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onAdd: () => _showAddTaskSheet(context, ref, _selectedDay)),
                  )
                else ...[
                  // Pending Tasks
                  if (todayPending.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _TaskTile(task: todayPending[i], ref: ref),
                        childCount: todayPending.length,
                      ),
                    ),
                  
                  // Completed Tasks
                  if (todayDone.isNotEmpty) ...[
                    if (todayPending.isNotEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Divider(color: AppColors.borderLight),
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _TaskTile(task: todayDone[i], ref: ref),
                        childCount: todayDone.length,
                      ),
                    ),
                  ],
                ],
  
                // ── Overdue Warn ───────────────────────────────────────────
                if (overdue.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                   SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Text(
                        'Overdue (${overdue.length})',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TaskTile(task: overdue[i], ref: ref),
                      childCount: overdue.length,
                    ),
                  ),
                ],
  
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref, DateTime? selectedDay) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFormSheet(ref: ref, initialDate: selectedDay),
    );
  }

  void _showEditTaskSheet(BuildContext context, WidgetRef ref, PlannerEntry task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFormSheet(ref: ref, existingEntry: task),
    );
  }
}

// ── Task Tile ──────────────────────────────────────────────────────────────
class _TaskTile extends StatelessWidget {
  final PlannerEntry task;
  final WidgetRef ref;

  const _TaskTile({required this.task, required this.ref});

  @override
  Widget build(BuildContext context) {
    final categoryColor = getCategoryColor(task.category);
    final categoryIcon = _getCategoryIcon(task.category);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const PhosphorIcon(PhosphorIconsRegular.trash, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.heavyImpact();
        ref.read(plannerProvider.notifier).deleteTask(task.id);
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(plannerProvider.notifier).toggleDone(task.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.borderLight
                      : categoryColor.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                   // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? AppColors.success : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted ? AppColors.success : categoryColor,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: task.isCompleted 
                        ? AppColors.surfaceSecondary 
                        : categoryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: PhosphorIcon(
                      categoryIcon, 
                      color: task.isCompleted ? AppColors.textTertiary : categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title + details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _displayCategory(task.category),
                              style: AppTextStyles.caption.copyWith(
                                color: task.isCompleted ? AppColors.textTertiary : categoryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimeRange(task.dueDate, task.endTime),
                              style: AppTextStyles.caption.copyWith(
                                color: task.isOverdue && !task.isCompleted ? AppColors.error : AppColors.textTertiary,
                              ),
                            ),
                            if (task.reminderOffset != null && !task.isCompleted) ...[
                              const SizedBox(width: 8),
                              const PhosphorIcon(PhosphorIconsRegular.bell, size: 12, color: AppColors.textTertiary),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Edit Button (Restricted for Overdue)
                  if (!task.dueDate.isBefore(DateTime.now()))
                    IconButton(
                      icon: PhosphorIcon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.primary.withValues(alpha: 0.6)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Accessing the parent state's showEdit method via context/ref if possible
                        // But since _TaskTile is inside PlannerScreen, we can just trigger it if we pass the callback
                        // For simplicity in this local private widget, we'll use a hack or just define the method here
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _TaskFormSheet(ref: ref, existingEntry: task),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeRange(DateTime start, DateTime? end) {
    if (end == null) {
      return DateFormat('h:mm a').format(start);
    }
    return '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}';
  }

  static String _displayCategory(String cat) {
    switch (cat) {
      case 'clinical_duty': return 'Clinical';
      case 'exam': return 'Exam';
      case 'return_demo': return 'Re-Demo';
      case 'todo': return 'To-do';
      case 'reminder': return 'Reminder';
      default: return 'Task';
    }
  }

  static Color getCategoryColor(String cat) {
    switch (cat) {
      case 'clinical_duty': return AppColors.primary;
      case 'exam': return AppColors.accent;
      case 'return_demo': return AppColors.primaryDark;
      case 'todo': return AppColors.secondary;
      case 'reminder': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'clinical_duty': return PhosphorIconsRegular.stethoscope;
      case 'exam': return PhosphorIconsRegular.pencilSimple;
      case 'return_demo': return PhosphorIconsRegular.videoCamera;
      case 'todo': return PhosphorIconsRegular.checkSquareOffset;
      case 'reminder': return PhosphorIconsRegular.bellRinging;
      default: return PhosphorIconsRegular.list;
    }
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  // onAdd kept for API compatibility but we no longer show a duplicate button
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight,
                  AppColors.accentLight,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const PhosphorIcon(
              PhosphorIconsRegular.calendarCheck,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text('No tasks for this day', style: AppTextStyles.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free time, or tap \'+\' below\nto add clinical duties and exams.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Subtle arrow pointing down to the FAB — no duplicate button
          const PhosphorIcon(
            PhosphorIconsRegular.arrowDown,
            color: AppColors.primary,
            size: 24,
          ),
        ],
      ),
    );
  }
}

// ── Task Form Bottom Sheet (Add/Edit) ──────────────────────────────────────
class _TaskFormSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final DateTime? initialDate;
  final PlannerEntry? existingEntry;
  const _TaskFormSheet({required this.ref, this.initialDate, this.existingEntry});

  @override
  ConsumerState<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<_TaskFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'todo';
  late DateTime _dueDate;
  DateTime? _endTime;
  int? _reminderOffset; 
  
  bool get isEdit => widget.existingEntry != null;

  static const _categoryMap = {
    'clinical_duty': 'Clinical',
    'exam': 'Exam',
    'return_demo': 'Re-Demo',
    'todo': 'To-do',
    'reminder': 'Reminder',
  };

  static const _reminderOptions = [
    {'lbl': 'None', 'val': null},
    {'lbl': '15m', 'val': 15},
    {'lbl': '1h', 'val': 60},
    {'lbl': '1d', 'val': 1440},
  ];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final entry = widget.existingEntry!;
      _titleCtrl.text = entry.title;
      _descCtrl.text = entry.description ?? '';
      _category = entry.category;
      _dueDate = entry.dueDate;
      _endTime = entry.endTime;
      _reminderOffset = entry.reminderOffset;
    } else {
      final now = DateTime.now();
      _dueDate = widget.initialDate != null 
          ? DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day, now.hour + 1, 0)
          : DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24, 16, 24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMedium,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(isEdit ? 'Edit Task' : 'New Task', style: AppTextStyles.headingMedium),
                const SizedBox(height: 20),

                // Title
                TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Duty title...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 14),

                // Category selector scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categoryMap.entries.map((entry) {
                      final selected = entry.key == _category;
                      final color = _TaskTile.getCategoryColor(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _category = entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? color : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: selected ? color : color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              entry.value,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: selected ? Colors.white : color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Time Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, h:mm a').format(_dueDate),
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End (Optional)', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _endTime != null ? DateFormat('h:mm a').format(_endTime!) : 'Not set',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: _endTime != null ? AppColors.textPrimary : AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                  if (_endTime != null)
                                    GestureDetector(
                                      onTap: () => setState(() => _endTime = null),
                                      child: const PhosphorIcon(PhosphorIconsRegular.xCircle, size: 16, color: AppColors.textTertiary),
                                    )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Reminders
                Row(
                  children: [
                    const PhosphorIcon(PhosphorIconsRegular.bell, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('Reminder', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    const Spacer(),
                    ..._reminderOptions.map((opt) {
                      final isSel = _reminderOffset == opt['val'];
                      return GestureDetector(
                        onTap: () => setState(() => _reminderOffset = opt['val'] as int?),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            opt['lbl'] as String,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSel ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 14),

                // Notes
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Description or notes...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(isEdit ? 'Update Task' : 'Save Task',
                        style: AppTextStyles.buttonLarge.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    
    // ignore: use_build_context_synchronously
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueDate));
    if (time == null) return;
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickEndDate() async {
    // End time uses same date as due date
    final time = await showTimePicker(
      context: context, 
      initialTime: _endTime != null ? TimeOfDay.fromDateTime(_endTime!) : TimeOfDay.fromDateTime(_dueDate),
    );
    if (time == null) return;
    setState(() {
      _endTime = DateTime(_dueDate.year, _dueDate.month, _dueDate.day, time.hour, time.minute);
    });
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    
    if (isEdit) {
      ref.read(plannerProvider.notifier).editTask(
        id: widget.existingEntry!.id,
        title: title,
        category: _category,
        dueDate: _dueDate,
        endTime: _endTime,
        reminderOffset: _reminderOffset,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
    } else {
      ref.read(plannerProvider.notifier).addTask(
        title: title,
        category: _category,
        dueDate: _dueDate,
        endTime: _endTime,
        reminderOffset: _reminderOffset,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
    }
    Navigator.of(context).pop();
  }
}