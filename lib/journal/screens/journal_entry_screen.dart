import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../../shared/widgets/hilway_background.dart';
import '../../shared/widgets/hilway_glass.dart';
import '../../shared/widgets/hilway_card.dart';
import '../../shared/widgets/responsive_wrapper.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  final JournalEntry? entry;

  const JournalEntryScreen({super.key, this.entry});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isReadOnly;
  double? _selectedMoodIndex;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
    _selectedMoodIndex = widget.entry?.moodIndex;
    // Default to read-only if viewing an existing entry
    _isReadOnly = widget.entry != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title and some content.')),
      );
      return;
    }

    if (widget.entry == null) {
      ref
          .read(journalProvider.notifier)
          .addEntry(title, content, moodIndex: _selectedMoodIndex);
    } else {
      ref
          .read(journalProvider.notifier)
          .updateEntry(
            widget.entry!,
            title,
            content,
            moodIndex: _selectedMoodIndex,
          );
    }

    context.pop();
  }

  String _getEmotionFromIndex(double? index) {
    if (index == null) return 'default';
    final idx = index.toInt();
    if (idx == 0) return 'calm'; // Calm
    if (idx == 1) return 'happy'; // Happy
    if (idx == 2) return 'excited'; // Energetic
    if (idx == 3) return 'concerned'; // Anxious
    if (idx == 4) return 'sad'; // Sad
    if (idx == 5) return 'sad'; // Depressed
    return 'default';
  }

  @override
  Widget build(BuildContext context) {
    final emotion = _getEmotionFromIndex(_selectedMoodIndex);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HilwayBackground(
        emotion: emotion,
        child: ResponsiveWrapper(
          child: Stack(
            children: [
              // ── Scrollable Form Area ──────────────────────────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        readOnly: _isReadOnly,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTextStyles.headingMedium.copyWith(
                          fontSize: 28,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Entry Title',
                          hintStyle: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.textTertiary.withValues(
                              alpha: 0.4,
                            ),
                            fontSize: 28,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Premium Mood Picker ───────────────────────────────────────
                      if (!_isReadOnly || _selectedMoodIndex != null) ...[
                        Text(
                          _isReadOnly
                              ? "HOW YOU WERE FEELING"
                              : "HOW ARE YOU FEELING?",
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: List.generate(
                              AppConstants.moodEmojis.length,
                              (index) {
                                final isSelected =
                                    _selectedMoodIndex == index.toDouble();

                                // In read-only mode, only show the selected mood
                                if (_isReadOnly && !isSelected)
                                  return const SizedBox.shrink();

                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: GestureDetector(
                                    onTap: _isReadOnly
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedMoodIndex = isSelected
                                                  ? null
                                                  : index.toDouble();
                                            });
                                          },
                                    child: HilwayCard(
                                      isGlass: true,
                                      width: null,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : Colors.white.withValues(alpha: 0.2),
                                      glowColor: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            AppConstants
                                                .moodAnimatedAssets[index],
                                            width: 28,
                                            height: 28,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            AppConstants.moodLabels[index],
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color: isSelected
                                                      ? AppColors.primaryDark
                                                      : AppColors.textPrimary,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w800
                                                      : FontWeight.w400,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      TextField(
                        controller: _contentController,
                        readOnly: _isReadOnly,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTextStyles.bodyLarge.copyWith(
                          height: 1.7,
                          fontSize: 18,
                        ),
                        maxLines: null,
                        minLines: 10,
                        decoration: InputDecoration(
                          hintText: 'Start writing your thoughts...',
                          hintStyle: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textTertiary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Premium Glass Header ─────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HilwayGlass(
                  sigmaX: 12,
                  sigmaY: 12,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.1),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      bottom: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const PhosphorIcon(PhosphorIconsRegular.x),
                          onPressed: () => context.pop(),
                        ),
                        Text(
                          widget.entry == null
                              ? 'New Reflection'
                              : (_isReadOnly
                                    ? 'Reflection'
                                    : 'Edit Reflection'),
                          style: AppTextStyles.headingSmall,
                        ),
                        const Spacer(),
                        if (_isReadOnly)
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _isReadOnly = false),
                            icon: const PhosphorIcon(
                              PhosphorIconsRegular.pencilSimpleLine,
                              size: 18,
                            ),
                            label: Text(
                              'EDIT',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: _saveEntry,
                            child: Text(
                              'SAVE',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
