import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/hilway_background.dart';
import '../providers/shift_provider.dart';
import '../models/shift_task.dart';

class ClinicalDutyScreen extends ConsumerStatefulWidget {
  const ClinicalDutyScreen({super.key});

  @override
  ConsumerState<ClinicalDutyScreen> createState() => _ClinicalDutyScreenState();
}

class _ClinicalDutyScreenState extends ConsumerState<ClinicalDutyScreen> {
  @override
  Widget build(BuildContext context) {
    final shiftTasks = ref.watch(shiftProvider);
    final pendingCount = shiftTasks.where((t) => !t.isDone).length;
    final progress = shiftTasks.isEmpty ? 0.0 : 1.0 - (pendingCount / shiftTasks.length);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Shift Buddy', style: AppTextStyles.headingSmall),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.arrowsClockwise, color: AppColors.textPrimary),
            tooltip: 'Reset Progress',
            onPressed: () => _showResetConfirmation(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: HilwayBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Current Shift', style: AppTextStyles.headingMedium),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: pendingCount == 0 && shiftTasks.isNotEmpty
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    shiftTasks.isEmpty
                                        ? 'No tasks'
                                        : (pendingCount == 0 ? 'Completed' : '$pendingCount pending'),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: pendingCount == 0 && shiftTasks.isNotEmpty
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceSecondary,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Shift Checklist', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (shiftTasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('No tasks added yet.', style: AppTextStyles.bodyMedium),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = shiftTasks[index];
                      return Dismissible(
                        key: Key(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                          ),
                          child: const Icon(Icons.delete_outline, color: AppColors.error),
                        ),
                        onDismissed: (_) {
                          ref.read(shiftProvider.notifier).deleteTask(task.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                ref.read(shiftProvider.notifier).toggleDone(task.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: task.isDone ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.15),
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
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: task.isDone ? AppColors.success : Colors.transparent,
                                        border: Border.all(
                                          color: task.isDone ? AppColors.success : AppColors.textTertiary,
                                          width: 2,
                                        ),
                                      ),
                                      child: task.isDone
                                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                                              color: task.isDone ? AppColors.textTertiary : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            task.category,
                                            style: AppTextStyles.caption.copyWith(
                                              color: task.isDone ? AppColors.textTertiary : AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: shiftTasks.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text('This will uncheck all tasks for a new shift.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shiftProvider.notifier).resetProgress();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Shift Task', style: AppTextStyles.headingSmall),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Check Patient Vitals',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Routine, Meds, Handover',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (titleController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                    ref.read(shiftProvider.notifier).addTask(
                      titleController.text,
                      categoryController.text,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
